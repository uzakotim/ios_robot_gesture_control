//
//  AudioManager.swift
//  ios_robot_gesture_control
//
//  Created by Timur Uzakov on 22/02/26.
//

import AVFoundation

class RobotSoundEngine {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var outputFormat: AVAudioFormat!

    init() {
        setupAudioSession()
        setupEngine()
    }

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
    }

    private func setupEngine() {
        engine.attach(player)
        // Obtain the current output format (sample rate + channel count)
        outputFormat = engine.outputNode.outputFormat(forBus: 0)
        // Connect player to main mixer with the output format to ensure consistency
        engine.connect(player, to: engine.mainMixerNode, format: outputFormat)

        do {
            try engine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }
    }

    func playChirp(startFreq: Double,
                   endFreq: Double,
                   duration: Double,
                   volume: Float = 0.3) {
        guard let format = outputFormat else { return }

        let sampleRate = format.sampleRate
        let channels = Int(format.channelCount)
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        // Generate a mono chirp, then duplicate to all channels to match the output format
        let monoSamplesCount = Int(frameCount)
        var mono = [Float](repeating: 0, count: monoSamplesCount)
        for i in 0..<monoSamplesCount {
            let progress = Double(i) / Double(monoSamplesCount)
            let freq = startFreq + (endFreq - startFreq) * progress
            let theta = 2.0 * Double.pi * freq * Double(i) / sampleRate
            mono[i] = Float(sin(theta)) * volume
        }

        if let channelData = buffer.floatChannelData {
            for ch in 0..<channels {
                let dst = channelData[ch]
                mono.withUnsafeBufferPointer { src in
                    dst.assign(from: src.baseAddress!, count: monoSamplesCount)
                }
            }
        }

        if !player.isPlaying {
            player.play()
        }
        player.scheduleBuffer(buffer, at: nil, options: [])
    }
}

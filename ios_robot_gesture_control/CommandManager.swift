//
//  CommandManager.swift
//  ios_robot_gesture_control
//
//  Created by Antigravity on 10/05/26.
//

import Foundation
import Network
import Combine

enum SequenceAction {
    case command(String)
    case pause(TimeInterval)
}

@MainActor
class CommandManager: ObservableObject {
    @Published var currentCommand: String = ""
    @Published var isPlayingSequence: Bool = false
    @Published var isAudioFeedbackEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isAudioFeedbackEnabled, forKey: "audio_feedback_enabled")
        }
    }
    private var sequenceTask: Task<Void, Never>?
    
    private var lastCommand: String = ""
    private var udpConnection: NWConnection?
    private let soundEngine = RobotSoundEngine()
    private var lastSoundTime = Date()

    let commandSequences: [String: [SequenceAction]] = [
        "happiness": [
            .command("q 200"),.pause(0.01), .command("q 200"),.pause(0.1),.pause(0.1), // Quick wiggle
            .command("e 200"),.pause(0.01), .command("e 200"),.pause(0.1),.pause(0.1),
            .command("q 200"),.pause(0.01), .command("q 200"),.pause(0.1),.pause(0.1),
            .command("e 200"),.pause(0.01), .command("e 200"),.pause(0.1),.pause(0.1),
            .command("w 180"),.pause(0.01), .command("w 180"),.pause(0.1),.pause(0.1), // Happy jump forward
            .command("k 0"),
            .command("k 0"),
            .command("k 0")
        ],
        "sadness": [
            .command("s 200"),.pause(0.01), .command("s 200"),.pause(0.2),// Slow slump back
            .command("q 150"), .pause(1.2), // Slow look down/side
            .command("k 0"),
            .command("k 0"),
            .command("k 0")
        ],
        "anger": [
            .command("w 200"),.pause(0.01), .command("w 200"), .pause(0.1), // Aggressive vibration
            .command("s 200"),.pause(0.01), .command("s 200"), .pause(0.1),
            .command("w 200"),.pause(0.01), .command("w 200"), .pause(0.1),
            .command("s 200"),.pause(0.01), .command("s 200"), .pause(0.1),
            .command("q 200"),.pause(0.01), .command("q 200"), .pause(0.5), // Aggressive turn
            .command("e 200"),.pause(0.01), .command("e 200"), .pause(0.5),
            .command("k 0"),
            .command("k 0"),
            .command("k 0")
        ],
        "fear": [
            .command("s 200"),.pause(0.01), .command("s 200"), .pause(0.5), // Rapid retreat
            .command("q 180"),.pause(0.01), .command("q 180"), .pause(0.2), // Quick look around
            .command("e 180"),.pause(0.01), .command("e 180"), .pause(0.2),
            .command("s 200"),.pause(0.01), .command("s 200"), .pause(0.3), // More retreat
            .command("k 0"),
            .command("k 0"),
            .command("k 0")
        ],
        "disgust": [
            .command("s 160"),.pause(0.01), .command("s 160"), .pause(0.4), // Backing away slowly
            .command("e 190"),.pause(0.01), .command("e 190"), .pause(0.6), // Sharp "turning away"
            .command("k 0"),
            .command("k 0"),
            .command("k 0")
        ],
        "surprise": [
            .command("s 200"),.pause(0.01), .command("s 200"), .pause(0.2), // Sudden jump back
            .command("k 0"),.pause(0.01),.command("k 0"),      .pause(0.5),  // Freeze
            .command("q 170"),.pause(0.01), .command("q 170"), .pause(0.3), // Confused look
            .command("e 170"),.pause(0.01), .command("e 170"), .pause(0.3),
            .command("k 0"),
            .command("k 0"),
            .command("k 0")
        ]
    ]

    init() {
        let host = UserDefaults.standard.string(forKey: "robot_ip") ?? "192.168.1.100"
        let portString = UserDefaults.standard.string(forKey: "robot_port") ?? "8080"
        let port = UInt16(portString) ?? 8080
        self.isAudioFeedbackEnabled = UserDefaults.standard.object(forKey: "audio_feedback_enabled") as? Bool ?? true
        setupUDP(host: host, port: port)
    }

    func setupUDP(host: String, port: UInt16) {
        udpConnection?.cancel()
        
        udpConnection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!,
            using: .udp
        )
        udpConnection?.start(queue: .global())
    }

    func sendCommand(_ command: String, force: Bool = false) {
        if !force {
            guard command != lastCommand else { return }
        }
        lastCommand = command
        
        currentCommand = command

        // Audio feedback
        if isAudioFeedbackEnabled && Date().timeIntervalSince(lastSoundTime) >= 0.2 {
            playFeedbackSound(for: command)
            lastSoundTime = Date()
        }

        guard let data = command.data(using: .utf8) else { return }

        udpConnection?.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("UDP send error: \(error)")
            }
        }))
    }

    func executeSequence(named name: String) {
        guard let sequence = commandSequences[name], !isPlayingSequence else { return }
        
        isPlayingSequence = true
        
        sequenceTask = Task {
            for action in sequence {
                if Task.isCancelled { break }
                
                switch action {
                case .command(let cmd):
                    sendCommand(cmd, force: true)
                case .pause(let duration):
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                }
            }
            isPlayingSequence = false
            sequenceTask = nil
        }
    }
    
    func stopSequence() {
        sequenceTask?.cancel()
        isPlayingSequence = false
        sequenceTask = nil
        sendCommand("k 0", force: true)
        sendCommand("k 0", force: true)
    }

    private func playFeedbackSound(for command: String) {
        if command.contains("w") {
            soundEngine.playChirp(startFreq: 500, endFreq: 900, duration: 0.20)
        } else if command.contains("s") {
            soundEngine.playChirp(startFreq: 700, endFreq: 900, duration: 0.10)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.soundEngine.playChirp(startFreq: 900, endFreq: 500, duration: 0.12)
            }
        } else if command.contains("q") {
            soundEngine.playChirp(startFreq: 700, endFreq: 500, duration: 0.15)
        } else if command.contains("e") {
            soundEngine.playChirp(startFreq: 500, endFreq: 700, duration: 0.15)
        }
    }
}

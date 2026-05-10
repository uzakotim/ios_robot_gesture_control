//
//  CommandManager.swift
//  ios_robot_gesture_control
//
//  Created by Antigravity on 10/05/26.
//

import Foundation
import Network
import Combine

@MainActor
class CommandManager: ObservableObject {
    @Published var currentCommand: String = ""
    private var lastCommand: String = ""
    private var udpConnection: NWConnection?
    private let soundEngine = RobotSoundEngine()
    private var lastSoundTime = Date()

    init() {
        setupUDP(host: "192.168.1.100", port: 8080)
    }

    func setupUDP(host: String, port: UInt16) {
        udpConnection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!,
            using: .udp
        )
        udpConnection?.start(queue: .global())
    }

    func sendCommand(_ command: String) {
        guard command != lastCommand else { return }
        lastCommand = command
        
        currentCommand = command

        // Audio feedback
        if Date().timeIntervalSince(lastSoundTime) >= 0.2 {
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

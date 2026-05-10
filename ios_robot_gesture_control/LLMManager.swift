import Foundation
import CoreMLLLM
import SwiftUI
import Combine

class LLMManager: ObservableObject {
    private var llm: CoreMLLLM?
    
    @Published var lastEmotion: String = "neutral"
    @Published var isProcessing: Bool = false
    @Published var isModelLoaded: Bool = false
    
    var commandManager: CommandManager?
    
    // Emotion to Emoji mapping
    private let emotionEmojis: [String: String] = [
        "happiness": "😊",
        "sadness": "😢",
        "anger": "😠",
        "fear": "😨",
        "disgust": "🤢",
        "surprise": "😲",
        "neutral": "😐"
    ]
    
    var currentEmoji: String {
        emotionEmojis[lastEmotion] ?? "🤔"
    }
    
    init() {
        Task {
            await setupLLM()
        }
    }
    
    @MainActor
    private func setupLLM() async {
        do {
            // 2. Fallback to downloading if not bundled
            print("Downloading: lfm2.5-350m")
            self.llm = try await CoreMLLLM.load(repo: "lfm2.5-350m") { print($0) }
            self.isModelLoaded = true
            print("CoreML-LLM Initialized successfully")
        } catch {
            print("Failed to initialize CoreML-LLM: \(error)")
        }
    }

    
    func classifyEmotion(text: String) {
        Task {
            await performClassification(text: text)
        }
    }
    
    @MainActor
    private func performClassification(text: String) async {
        guard let llm = llm else {
            print("LLM not initialized")
            return
        }
        
        self.isProcessing = true
        
        let prompt = """
        Classify the following text into exactly one of these six emotions: happiness, sadness, anger, fear, disgust, surprise.
        Return ONLY the emotion word.
        
        Text: "\(text)"
        Emotion:
        """
        
        do {
            let result = try await llm.generate(prompt)
            let cleanedResult = result.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            // Find if any of our keys is in the result
            let detectedEmotion = self.emotionEmojis.keys.first { cleanedResult.contains($0) } ?? "neutral"
            
            if detectedEmotion != "neutral" {
                commandManager?.executeSequence(named: detectedEmotion)
            }
            
            
            self.lastEmotion = detectedEmotion
            self.isProcessing = false
            commandManager?.sendCommand("k 0")
            print("Detected Emotion: \(detectedEmotion)")
        } catch {
            print("Inference failed: \(error)")
            self.isProcessing = false
            commandManager?.sendCommand("k 0")
        }
    }
}

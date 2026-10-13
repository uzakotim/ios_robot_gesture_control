import Foundation
import SwiftUI
import Combine
import LLM

class LLMManager: ObservableObject {
    private var llm : LLM?
    
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
            guard let modelURL = Bundle.main.url(
                       forResource: "gemma-2-2b-it-Q4_K_M",
                       withExtension: "gguf"
                   ) else {
                       print("Модель не найдена в Bundle!")
                       return
                   }
            
            self.llm = LLM(from: modelURL, template: .gemma,maxTokenCount: 32000)
            self.isModelLoaded = true
            print("LLM Initialized successfully")
            
        }
    }
    
    
    func classifyEmotion(text: String) {
        Task {
            await performClassification(text: text)
        }
    }
    
    
    @MainActor
    private func makeLLM() -> LLM? {
        guard let modelURL = Bundle.main.url(
            forResource: "gemma-2-2b-it-Q4_K_M",
            withExtension: "gguf"
        ) else {
            return nil
        }

        return LLM(
            from: modelURL,
            template: .chatML(
                "You are a happy robot that responds with emotions"
            ),
            maxTokenCount: 2048
        )
    }
    
    @MainActor
    func performClassification(text: String) async {
        // Prevent overlapping inference requests.
        guard !isProcessing else {
            print("Classification already in progress; skipping request.")
            return
        }

        guard let llm = self.llm else {
            print("LLM is not initialized")
            return
        }

        isProcessing = true
        defer {
            isProcessing = false
        }

        guard let freshLLM = makeLLM() else {
            print("Could not initialize LLM")
            return
        }
        

        let prompt = """
        Classify this text into exactly one emotion:
        happiness, sadness, anger, fear, disgust, surprise.

        
        Text: "\(text)"
        
        Return ONLY the emotion word, NO COMMENTS, NO EXPLANATION
        """

        await freshLLM.respond(to: prompt)

        let result = freshLLM.output
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        print("Raw LLM output: \(result)")
        
        let emotions = [
            "happiness", "sadness", "anger",
            "fear", "disgust", "surprise"
        ]

        let cleanedResult = result
            .replacingOccurrences(of: "&#x20;", with: " ")
            .replacingOccurrences(of: "<|im_end|>", with: "")
            .replacingOccurrences(of: "<|endoftext|>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let detectedEmotion = emotions.first { emotion in
            cleanedResult
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .contains(emotion)
        } ?? "neutral"

        print("Detected Emotion: \(detectedEmotion)")

        lastEmotion = detectedEmotion

        if detectedEmotion != "neutral" {
            commandManager?.executeSequence(named: detectedEmotion)
        }

        commandManager?.sendCommand("k 0")

        print("Detected Emotion: \(detectedEmotion)")
    }
}

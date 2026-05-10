import Foundation
import Speech
import AVFoundation
import Combine

enum SpeechLanguage: String {
    case english = "en-US"
    case russian = "ru-RU"
    
    var title: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        }
    }
}

class SpeechRecognitionManager: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isCommandModeActive: Bool = false
    @Published var isListening: Bool = false
    @Published var currentLanguage: SpeechLanguage = .russian {
        didSet {
            if isListening {
                startListening()
            }
        }
    }
    
    private let audioEngine = AVAudioEngine()
    
    private var engRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var rusRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    
    private var activeRequest: SFSpeechAudioBufferRecognitionRequest?
    private var activeTask: SFSpeechRecognitionTask?
    private var currentTaskID: UUID?
    
    @Published var currentSpeech: String = ""
    private var llmTimer: Timer?
    private var restartTimer: Timer?
    
    // LLM for emotion detection
    let llmManager = LLMManager()
    
    init(commandManager: CommandManager? = nil) {
        self.llmManager.commandManager = commandManager
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                    self?.startListening()
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition not authorized")
                @unknown default:
                    break
                }
            }
        }
    }
    
    func startListening() {
        // Stop any existing tasks
        stopListening(resetState: false)
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        activeRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = activeRequest else { return }
        request.shouldReportPartialResults = true
        request.contextualStrings = ["Byte", "Байт", "Ayte","Айт"]
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.activeRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                self.recognizedText = self.currentLanguage == .english ? "Listening..." : "Слушаю..."
            }
        } catch {
            print("Audio engine failed to start: \(error)")
            return
        }
        
        let recognizerToUse = currentLanguage == .english ? engRecognizer : rusRecognizer
        
        let taskID = UUID()
        self.currentTaskID = taskID
        
        activeTask = recognizerToUse?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            guard self.currentTaskID == taskID else { return }
            self.handleResult(result: result, error: error)
        }
        
        resetTimers()
    }
    
    func stopListening(resetState: Bool = true) {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        activeRequest?.endAudio()
        activeTask?.cancel()
        
        activeRequest = nil
        activeTask = nil
        
        llmTimer?.invalidate()
        restartTimer?.invalidate()
        
        DispatchQueue.main.async {
            self.isListening = false
            if resetState {
                self.isCommandModeActive = false
                self.recognizedText = ""
                self.currentSpeech = ""
            }
        }
    }
    
    private func handleResult(result: SFSpeechRecognitionResult?, error: Error?) {
        guard let result = result else { return }
        
        let text = result.bestTranscription.formattedString
        
        DispatchQueue.main.async {
            // Only update text if it's not empty and we're actively listening
            if !text.isEmpty && self.isListening {
                var displayText = text
                
                // Erase previous words from the display by taking the LAST occurrence of any wake word
                let wakeWords = ["byte","бай", "байт","ayte","ay","ite", "айт"]
                var bestRange: Range<String.Index>? = nil
                
                for word in wakeWords {
                    if let range = text.range(of: word, options: [.caseInsensitive, .backwards]) {
                        if bestRange == nil || range.lowerBound > bestRange!.lowerBound {
                            bestRange = range
                        }
                    }
                }
                
                if let bestRange = bestRange {
                    self.isCommandModeActive = true
                    displayText = String(text[bestRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                self.recognizedText = displayText
                self.currentSpeech = displayText
                self.resetTimers()
            } else if let error = error {
                print("Speech recognition error: \(error)")
            }
        }
    }
    
    private func resetTimers() {
        llmTimer?.invalidate()
        restartTimer?.invalidate()
        
        // 3 seconds of silence -> send to LLM and clear currentSpeech
        llmTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if !self.currentSpeech.isEmpty && self.isCommandModeActive {
                    self.sendToLLM(text: self.currentSpeech)
                    self.currentSpeech = ""
                    self.recognizedText = ""
                    self.isCommandModeActive = false
                    self.startListening() // Restart to flush SFSpeechRecognizer's internal transcript
                }
            }
        }
        
        // 5 seconds of silence -> restart listening
        restartTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                // When the pause (5 sec) is over, reset state and start listening again
                self?.isCommandModeActive = false
                self?.currentSpeech = ""
                self?.recognizedText = ""
                self?.startListening()
            }
        }
    }
    
    private func sendToLLM(text: String) {
        print("Sending to LLM: \(text)")
        llmManager.classifyEmotion(text: text)
    }
}

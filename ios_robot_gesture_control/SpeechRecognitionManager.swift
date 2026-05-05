import Foundation
import Speech
import AVFoundation
import Combine

class SpeechRecognitionManager: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isCommandModeActive: Bool = false
    @Published var isListening: Bool = false
    
    private let audioEngine = AVAudioEngine()
    
    private var engRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var rusRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    
    private var engRequest: SFSpeechAudioBufferRecognitionRequest?
    private var rusRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var engTask: SFSpeechRecognitionTask?
    private var rusTask: SFSpeechRecognitionTask?
    
    @Published var currentSpeech: String = ""
    private var llmTimer: Timer?
    private var restartTimer: Timer?
    
    init() {
        // Authorization is requested when the view appears
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
        
        engRequest = SFSpeechAudioBufferRecognitionRequest()
        rusRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let engReq = engRequest, let rusReq = rusRequest else { return }
        
        engReq.shouldReportPartialResults = true
        rusReq.shouldReportPartialResults = true
        
        // Attempt on-device recognition to allow concurrent tasks if possible
        if #available(iOS 13, *) {
            if engRecognizer?.supportsOnDeviceRecognition == true {
                engReq.requiresOnDeviceRecognition = true
            }
            if rusRecognizer?.supportsOnDeviceRecognition == true {
                rusReq.requiresOnDeviceRecognition = true
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.engRequest?.append(buffer)
            self?.rusRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                self.recognizedText = "Listening..."
            }
        } catch {
            print("Audio engine failed to start: \(error)")
            return
        }
        
        engTask = engRecognizer?.recognitionTask(with: engReq) { [weak self] result, error in
            self?.handleResult(result: result, error: error, language: "EN")
        }
        
        rusTask = rusRecognizer?.recognitionTask(with: rusReq) { [weak self] result, error in
            self?.handleResult(result: result, error: error, language: "RU")
        }
        
        resetTimers()
    }
    
    func stopListening(resetState: Bool = true) {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        engRequest?.endAudio()
        rusRequest?.endAudio()
        
        engTask?.cancel()
        rusTask?.cancel()
        
        engRequest = nil
        rusRequest = nil
        engTask = nil
        rusTask = nil
        
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
    
    private func handleResult(result: SFSpeechRecognitionResult?, error: Error?, language: String) {
        guard let result = result else { return }
        
        let text = result.bestTranscription.formattedString
        
        DispatchQueue.main.async {
            // Only update text if it's not empty and we're actively listening
            if !text.isEmpty && self.isListening {
                var displayText = text
                
                // Erase previous words from the display by taking the LAST occurrence of "byte" or "байт"
                let byteRange = text.range(of: "byte", options: [.caseInsensitive, .backwards])
                let baitRange = text.range(of: "байт", options: [.caseInsensitive, .backwards])
                
                if let br = byteRange, let btr = baitRange {
                    let bestRange = br.lowerBound > btr.lowerBound ? br : btr
                    displayText = String(text[bestRange.lowerBound...])
                } else if let br = byteRange {
                    displayText = String(text[br.lowerBound...])
                } else if let btr = baitRange {
                    displayText = String(text[btr.lowerBound...])
                }
                
                self.recognizedText = displayText
                self.currentSpeech = displayText
                self.checkForWakeWord(text: displayText)
                self.resetTimers()
            }
        }
    }
    
    private func checkForWakeWord(text: String) {
        let lowerText = text.lowercased()
        // If we hear the wake word, we activate command mode
        if lowerText.contains("byte") || lowerText.contains("байт") {
            if !isCommandModeActive {
                isCommandModeActive = true
                // Vibrate or play sound here if needed
            }
        }
    }
    
    private func resetTimers() {
        llmTimer?.invalidate()
        restartTimer?.invalidate()
        
        // 3 seconds of silence -> send to LLM and clear currentSpeech
        llmTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
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
        restartTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
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
        // Stub for sending the text to LLM (dummy)
        print("Sending to LLM: \(text)")
    }
}

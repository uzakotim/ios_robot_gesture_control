//
//  ContentView.swift
//  ios_robot_gesture_control
//
//  Created by Timur Uzakov on 14/02/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    @StateObject private var commandManager: CommandManager
    @StateObject private var cameraManager: CameraManager
    @StateObject private var speechManager: SpeechRecognitionManager
    @State private var showingSettings = false
    
    @State private var showingColorPalette = false
    @State private var robotEyeColor: Color = .yellow
    let eyeColors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .indigo]
    
    init() {
        let cmdManager = CommandManager()
        _commandManager = StateObject(wrappedValue: cmdManager)
        _cameraManager = StateObject(wrappedValue: CameraManager(commandManager: cmdManager))
        _speechManager = StateObject(wrappedValue: SpeechRecognitionManager(commandManager: cmdManager))
    }
    
    var body: some View {
        ZStack {
            
            // Camera layer (bottom)
            CameraPreview(cameraManager: cameraManager)
                .ignoresSafeArea()
                .opacity(0.7)
            
            // Robot face overlay (top)
            RobotEyesOverlay(cameraManager: cameraManager, commandManager: commandManager, eyeColor: robotEyeColor) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingColorPalette = true
                }
            }
            .ignoresSafeArea()
            
            // Color Palette Layer
            if showingColorPalette {
                Color.black.opacity(0.01) // Catch taps elsewhere
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showingColorPalette = false
                        }
                    }
                
                VStack {
                    Spacer()
                    HStack(spacing: 15) {
                        ForEach(eyeColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: robotEyeColor == color ? 3 : 0)
                                )
                                .shadow(color: color.opacity(0.8), radius: robotEyeColor == color ? 8 : 4)
                                .scaleEffect(robotEyeColor == color ? 1.1 : 1.0)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        robotEyeColor = color
                                    }
                                }
                        }
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(25)
                    .padding(.bottom, 120)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
                
            // Language Toggle Button
            VStack {
                HStack {
                    // Emotion Emoji Display
                    Text(speechManager.llmManager.currentEmoji)
                        .font(.system(size: 40))
                        .shadow(radius: 5)
                        .transition(.scale.combined(with: .opacity))
                        .id(speechManager.llmManager.lastEmotion) // Force animation on change
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            if speechManager.currentLanguage == .english {
                                speechManager.currentLanguage = .russian
                            } else {
                                speechManager.currentLanguage = .english
                            }
                        }) {
                            Text(speechManager.currentLanguage.title)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(20)
                        }
                    }
                    .padding()
                }
                Spacer()
            }
                
//            // Test Sequence Buttons
//            VStack {
//                Spacer()
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(["happiness", "sadness", "anger", "fear", "disgust", "surprise"], id: \.self) { emotion in
//                            Button(action: {
//                                commandManager.executeSequence(named: emotion)
//                            }) {
//                                HStack(spacing: 8) {
//                                    Text(emoji(for: emotion))
//                                        .font(.title3)
//                                    Text(emotion.capitalized)
//                                        .font(.system(size: 14, weight: .bold, design: .rounded))
//                                }
//                                .padding(.horizontal, 16)
//                                .padding(.vertical, 10)
//                                .background(
//                                    VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
//                                        .cornerRadius(20)
//                                )
//                                .foregroundColor(.white)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 20)
//                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
//                                )
//                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
//                                .opacity(commandManager.isPlayingSequence ? 0.5 : 1.0)
//                            }
//                            .buttonStyle(PlainButtonStyle())
//                            .disabled(commandManager.isPlayingSequence)
//                        }
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.bottom, 150)
//                }
//            }
//            
            // Speech Recognition Overlay
            VStack {
                Spacer()
                
                HStack(spacing: 4){
                    
                    if !speechManager.recognizedText.isEmpty || speechManager.llmManager.lastEmotion != "neutral" {
                        VStack(spacing: 10) {
                            
                            if speechManager.llmManager.isProcessing {
                                ProgressView()
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding()
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(12)
                            } else if !speechManager.llmManager.isModelLoaded {
                                ProgressView("Loading model...")
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding()
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(12)
                            }
                            else if !speechManager.recognizedText.isEmpty {
                                Text(speechManager.recognizedText)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(speechManager.isCommandModeActive ? .green : .white)
                                    .padding()
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.bottom, 10)
                        .animation(.spring(), value: speechManager.llmManager.lastEmotion)
                        .animation(.easeInOut, value: speechManager.isCommandModeActive)
                        
                        
                    }
                }
            }
        }
        .onAppear {
            speechManager.requestAuthorization()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(commandManager: commandManager)
        }
    }
    
    private func emoji(for emotion: String) -> String {
        switch emotion {
        case "happiness": return "😊"
        case "sadness": return "😢"
        case "anger": return "😠"
        case "fear": return "😨"
        case "disgust": return "🤢"
        case "surprise": return "😲"
        default: return "🤔"
        }
    }
}

// Helper for Blur Effect
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

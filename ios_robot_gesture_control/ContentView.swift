//
//  ContentView.swift
//  ios_robot_gesture_control
//
//  Created by Timur Uzakov on 14/02/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var speechManager = SpeechRecognitionManager()
    
    var body: some View {
        ZStack {
            
            // Camera layer (bottom)
            CameraPreview(cameraManager: cameraManager)
                .ignoresSafeArea()
                .opacity(0.7)
            
            // Robot face overlay (top)
            RobotEyesOverlay(cameraManager: cameraManager)
                .ignoresSafeArea()
                
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
                    .padding()
                }
                Spacer()
            }
                
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
    }
}

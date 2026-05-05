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
                
                if !speechManager.recognizedText.isEmpty {
                    Text(speechManager.recognizedText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(speechManager.isCommandModeActive ? .green : .white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .padding(.bottom, 20)
                        .animation(.easeInOut, value: speechManager.isCommandModeActive)
                } 
            }
        }
        .onAppear {
            speechManager.requestAuthorization()
        }
    }
}

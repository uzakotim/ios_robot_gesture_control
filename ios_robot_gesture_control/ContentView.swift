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

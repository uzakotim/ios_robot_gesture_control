//
//  ContentView.swift
//  ios_robot_gesture_control
//
//  Created by Timur Uzakov on 14/02/26.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
                  
                  // Camera layer (bottom)
                  CameraPreview(cameraManager: cameraManager)
                      .ignoresSafeArea()
                      .opacity(0.5)
                  
                  // Robot face overlay (top)
                  RobotEyesOverlay(cameraManager: cameraManager)
                      .ignoresSafeArea()
                      .opacity(0.9)
              }
    }
}

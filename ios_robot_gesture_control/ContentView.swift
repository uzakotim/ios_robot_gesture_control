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
            CameraPreview(cameraManager: cameraManager)
                .ignoresSafeArea()
        }
    }
}

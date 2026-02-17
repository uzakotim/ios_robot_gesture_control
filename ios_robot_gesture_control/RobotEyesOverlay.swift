//
//  RobotEyesOverlay.swift
//  ios_robot_gesture_control
//
//  Created by Timur Uzakov on 17/02/26.
//
import SwiftUI

struct RobotEyesOverlay: View {
    
    @ObservedObject var cameraManager: CameraManager
    
    
    
    @State private var eyeOffset: CGFloat = 0
    let horizontalOffset : CGFloat = 200
    
    var body: some View {
        GeometryReader { geo in
            
            ZStack {
                Color.clear
                
                HStack(spacing: geo.size.width * 0.06) {
                    
                    RobotEye(offset: eyeOffset)
                    RobotEye(offset: eyeOffset)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onChange(of: cameraManager.currentCommand) { oldValue, newValue in
                updateEyes(for: newValue)
            }
        }
    }
    
    private func updateEyes(for command: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if command.contains("q") {
                eyeOffset = horizontalOffset
            } else if command.contains("e") {
                eyeOffset = -horizontalOffset
            } else {
                eyeOffset = 0
            }
        }
    }
}

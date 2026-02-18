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
    @State private var eyeSize: CGFloat = 200
    let horizontalOffset : CGFloat = 200
    
    var body: some View {
        GeometryReader { geo in
            
            ZStack {
                Color.clear
                
                HStack(spacing: geo.size.width * 0.06) {
                    
                    RobotEye(offset: eyeOffset,eyeSize: eyeSize)
                    RobotEye(offset: eyeOffset, eyeSize: eyeSize)
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
                eyeSize = 200
            } else if command.contains("e") {
                eyeOffset = -horizontalOffset
                eyeSize = 200
            } else if command.contains("w"){
                eyeOffset = 0
                eyeSize = 250
            }
            else if command.contains("s"){
                eyeOffset = 0
                eyeSize = 150
            }
            else {
                eyeSize = 200
                eyeOffset = 0
            }
        }
    }
}

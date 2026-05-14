//
//  RobotEye.swift
//  ios_robot_gesture_control
//
//  Created by Timur Uzakov on 17/02/26.
//
import SwiftUI

struct RobotEye: View {
    
    var offsetX: CGFloat
    var offsetY: CGFloat
    var eyeSize: CGFloat
    var color: Color = .yellow
    
    var body: some View {
        
        RoundedRectangle(cornerRadius:50)
            .fill(color)
            .overlay(
                LinearGradient(
                    colors: [.white.opacity(0.2), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 50))
            .frame(width: eyeSize, height: eyeSize)
            .offset(x: offsetX, y: offsetY)
            .shadow(color: color.opacity(0.6), radius: 12)
    }
}

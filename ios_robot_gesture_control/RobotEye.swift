//
//  RobotEye.swift
//  ios_robot_gesture_control
//
//  Created by Timur Uzakov on 17/02/26.
//
import SwiftUI

struct RobotEye: View {
    
    var offset: CGFloat
    
    var body: some View {
        
        RoundedRectangle(cornerRadius:50)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.9, blue: 0.1),
                        Color.yellow
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 200, height: 200)
            .offset(x: offset)
            .shadow(color: .yellow.opacity(0.6), radius: 12)
    }
}

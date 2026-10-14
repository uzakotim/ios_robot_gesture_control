//
//  GlowingBorder.swift
//  ios_robot_gesture_control
//
//  Created by Timur Uzakov on 10/14/26.
//

import SwiftUI

struct GlowingBorderView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea() // Свечение лучше всего видно на темном фоне
            
            Text("Glow Effect")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 200, height: 60)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        // Рисуем рамку толщиной 2 пункта
                        .stroke(LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                        // Добавляем эффект размытого свечения (несколько слоев тени дают более сочный эффект)
                        .shadow(color: .cyan.opacity(0.8), radius: 8, x: 0, y: 0)
                        .shadow(color: .purple.opacity(0.5), radius: 15, x: 0, y: 0)
                )
        }
    }
}

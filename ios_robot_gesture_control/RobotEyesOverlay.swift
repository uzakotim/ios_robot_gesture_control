import SwiftUI

struct RobotEyesOverlay: View {
    
    @ObservedObject var cameraManager: CameraManager
    
    @State private var eyeOffsetX: CGFloat = 0
    @State private var eyeOffsetY: CGFloat = 0
    @State private var eyeSize: CGFloat = 200
    
    let horizontalCommandOffset: CGFloat = 200
    let followStrength: CGFloat = 400   // how far eyes can move when following finger
    
    var body: some View {
        GeometryReader { geo in
            
            ZStack {
                Color.clear
                
                HStack(spacing: geo.size.width * 0.05) {
                    
                    RobotEye(
                        offsetX: eyeOffsetX,
                        offsetY: eyeOffsetY,
                        eyeSize: eyeSize
                    )
                    
                    RobotEye(
                        offsetX: eyeOffsetX,
                        offsetY: eyeOffsetY,
                        eyeSize: eyeSize
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Movement mode (robot commands)
            .onChange(of: cameraManager.currentCommand) { _, newValue in
                updateEyes(for: newValue)
            }
            
            // Eye follow mode (index finger)
            .onChange(of: cameraManager.offsetX) { _, _ in
                followIndexFinger()
            }
            
            .onChange(of: cameraManager.offsetY) { _, _ in
                followIndexFinger()
            }
        }
    }
    
    // =========================================================
    // 🎮 COMMAND-BASED EYE MOVEMENT
    // =========================================================
    
    private func updateEyes(for command: String) {
        let firstChar = command.first ?? " "
        
        withAnimation(.easeInOut(duration: 0.2)) {
            switch firstChar {
                
            case "q":
                eyeOffsetX = horizontalCommandOffset
                eyeOffsetY = 0
                eyeSize = 200
                
            case "e":
                eyeOffsetX = -horizontalCommandOffset
                eyeOffsetY = 0
                eyeSize = 200
                
            case "w":
                eyeOffsetX = 0
                eyeOffsetY = 0
                eyeSize = 250
                
            case "s":
                eyeOffsetX = 0
                eyeOffsetY = 0
                eyeSize = 150
                
            default:
                eyeSize = 200
                eyeOffsetX = 0
                eyeOffsetY = 0
            }
        }
    }
    
    // =========================================================
    // 👆 INDEX FINGER FOLLOW MODE
    // =========================================================
    
    private func followIndexFinger() {
        
        let targetX = cameraManager.offsetX * followStrength
        let targetY = cameraManager.offsetY * followStrength
        
        // Smooth factor (0.0 - 1.0)
        let smoothing: CGFloat = 0.5
        
        eyeOffsetX = eyeOffsetX + (targetX - eyeOffsetX) * smoothing
        eyeOffsetY = eyeOffsetY + (targetY - eyeOffsetY) * smoothing
    }
}

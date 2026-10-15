import SwiftUI

enum EyeForm: Equatable {
    case neutral, happy, sad, angry, fearful, disgusted, surprised
}

/// Facial expression is independent from gaze/movement offsets.
struct EyeExpression: Equatable {
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    var eyelid: CGFloat = 0
    var form: EyeForm = .neutral

    static let neutral = EyeExpression()
}

struct RobotEye: View {
    enum Side {
        case left, right
        var multiplier: CGFloat { self == .left ? -1 : 1 }
    }

    var offsetX: CGFloat
    var offsetY: CGFloat
    var eyeSize: CGFloat
    var expression: EyeExpression = .neutral
    var side: Side
    var color: Color = .yellow

    var body: some View {
        Group {
            // Add .disgusted (and any other line-art forms) here so they use .stroke!
            if expression.form == .angry || expression.form == .disgusted || expression.form == .happy || expression.form == .sad {
                EyeSilhouette(form: expression.form, side: side)
                    .stroke(color, style: StrokeStyle(lineWidth: max(9, eyeSize * 0.105), lineCap: .round, lineJoin: .round))
                    .padding(.horizontal, eyeSize * 0.08)
                    .padding(.vertical, eyeSize * 0.16)
            } else {
                // Everything else uses .fill
                EyeSilhouette(form: expression.form, side: side)
                    .fill(LinearGradient(colors: [color.opacity(0.9), color, color.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(alignment: .top) {
                        if expression.eyelid > 0 {
                            Rectangle().fill(Color.black.opacity(0.72))
                                .frame(height: eyeSize * expression.eyelid)
                                .clipShape(EyeSilhouette(form: expression.form, side: side))
                        }
                    }
            }
        }
        .frame(width: eyeSize, height: eyeSize)
        .scaleEffect(x: expression.scaleX, y: expression.scaleY)
        .offset(x: offsetX + expression.offsetX, y: offsetY + expression.offsetY)
        .shadow(color: color.opacity(0.55), radius: 12)
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: expression)
        .accessibilityLabel("Robot eye")
    }
}

private struct EyeSilhouette: Shape {
    var form: EyeForm
    var side: RobotEye.Side

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        switch form {
        case .neutral:
            p.addRoundedRect(in: rect, cornerSize: CGSize(width: min(w * 0.28, h * 0.28), height: min(w * 0.28, h * 0.28)))
        case .happy:
            p.move(to: CGPoint(x: w * 0, y: h * 1))
            p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.0))
            p.addLine(to: CGPoint(x: w * 1.0, y: h * 1.0))
        case .disgusted:
            if side == .left {
                // Left eye: Sharp > shape spanning full width and height
                p.move(to: CGPoint(x: w * 0.0, y: h * 0.0))
                p.addLine(to: CGPoint(x: w * 1.0, y: h * 0.50))
                p.addLine(to: CGPoint(x: w * 0.0, y: h * 1.0))
            } else {
                // Right eye: Flat underscore _ shape spanning full width
                p.move(to: CGPoint(x: w * 0.0, y: h ))
                p.addLine(to: CGPoint(x: w * 1.0, y: h))
            }
        case .angry:
            // Example of different shapes for left vs right eye during angry/custom states!
            if side == .left {
                    // Left eye: > shape pointing right/inward, scaled to full box
                    p.move(to: CGPoint(x: w * 0.0, y: 0))
                    p.addLine(to: CGPoint(x: w * 1.0, y: h * 0.50))
                    p.addLine(to: CGPoint(x: w * 0.0, y: h * 1.0))
                } else {
                    // Right eye: < shape pointing left/inward, scaled to full box
                    p.move(to: CGPoint(x: w * 1.0, y: 0 ))
                    p.addLine(to: CGPoint(x: w * 0.0, y: h * 0.50))
                    p.addLine(to: CGPoint(x: w * 1.0, y: h * 1.0))
                }
        case .sad:
            if side == .left {
                // Left eye: spans full height from bottom-left to top-right ( / )
                p.move(to: CGPoint(x: w * 0.15, y: h * 1.0))
                p.addLine(to: CGPoint(x: w * 0.85, y: h * 0.0))
            } else {
                // Right eye: spans full height from top-left to bottom-right ( \ )
                p.move(to: CGPoint(x: w * 0.15, y: h * 0.0))
                p.addLine(to: CGPoint(x: w * 0.85, y: h * 1.0))
            }
        case .fearful, .surprised:
            let inset: CGFloat = form == .surprised ? 0.07 : 0.13
            p.addEllipse(in: rect.insetBy(dx: w * inset, dy: h * inset))
        }
        return p
    }
}

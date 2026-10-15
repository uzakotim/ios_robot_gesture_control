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
            if expression.form == .happy {
                // Pupil-free ^ shape, drawn with a rounded stroke.
                EyeSilhouette(form: .happy)
                    .stroke(color, style: StrokeStyle(lineWidth: max(9, eyeSize * 0.105), lineCap: .round, lineJoin: .round))
                    .padding(.horizontal, eyeSize * 0.08)
                    .padding(.vertical, eyeSize * 0.16)
            } else {
                EyeSilhouette(form: expression.form)
                    .fill(LinearGradient(colors: [color.opacity(0.9), color, color.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(alignment: .top) {
                        if expression.eyelid > 0 {
                            Rectangle().fill(Color.black.opacity(0.72))
                                .frame(height: eyeSize * expression.eyelid)
                                .clipShape(EyeSilhouette(form: expression.form))
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

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        switch form {
        case .neutral:
            p.addRoundedRect(in: rect, cornerSize: CGSize(width: min(w * 0.28, h * 0.28), height: min(w * 0.28, h * 0.28)))
        case .happy:
            p.move(to: CGPoint(x: w * 0.08, y: h * 0.82))
            p.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.2), control: CGPoint(x: w * 0.28, y: h * 0.2))
            p.addQuadCurve(to: CGPoint(x: w * 0.92, y: h * 0.82), control: CGPoint(x: w * 0.72, y: h * 0.2))
        case .angry:
            p.move(to: CGPoint(x: w * 0.04, y: h * 0.18))
            p.addLine(to: CGPoint(x: w * 0.96, y: h * 0.38))
            p.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.84), control: CGPoint(x: w * 0.98, y: h * 0.78))
            p.addLine(to: CGPoint(x: w * 0.18, y: h * 0.78)); p.closeSubpath()
        case .sad:
            p.move(to: CGPoint(x: w * 0.08, y: h * 0.3))
            p.addQuadCurve(to: CGPoint(x: w * 0.92, y: h * 0.3), control: CGPoint(x: w * 0.5, y: h * 0.92))
            p.addLine(to: CGPoint(x: w * 0.82, y: h * 0.76))
            p.addQuadCurve(to: CGPoint(x: w * 0.18, y: h * 0.76), control: CGPoint(x: w * 0.5, y: h * 0.48)); p.closeSubpath()
        case .fearful, .surprised:
            let inset: CGFloat = form == .surprised ? 0.07 : 0.13
            p.addEllipse(in: rect.insetBy(dx: w * inset, dy: h * inset))
        case .disgusted:
            p.move(to: CGPoint(x: w * 0.08, y: h * 0.22))
            p.addQuadCurve(to: CGPoint(x: w * 0.92, y: h * 0.35), control: CGPoint(x: w * 0.48, y: h * 0.02))
            p.addLine(to: CGPoint(x: w * 0.82, y: h * 0.7))
            p.addQuadCurve(to: CGPoint(x: w * 0.12, y: h * 0.76), control: CGPoint(x: w * 0.45, y: h * 0.58)); p.closeSubpath()
        }
        return p
    }
}

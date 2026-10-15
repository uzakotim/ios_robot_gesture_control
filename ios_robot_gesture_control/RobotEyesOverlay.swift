import SwiftUI

struct RobotEyesOverlay: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var commandManager: CommandManager

    var emotion: String = "neutral"
    var eyeColor: Color = .yellow
    var onEyesTapped: () -> Void = {}

    @State private var eyeOffsetX: CGFloat = 0
    @State private var eyeOffsetY: CGFloat = 0
    @State private var eyeSize: CGFloat = 200
    @State private var expression = EyeExpression.neutral
    @State private var emotionTask: Task<Void, Never>?

    private let horizontalCommandOffset: CGFloat = 200
    private let followStrength: CGFloat = 400

    private var isEmotionAnimating: Bool {
        commandManager.isPlayingSequence && emotion.lowercased() != "neutral"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.clear
                HStack(spacing: geo.size.width * 0.05) {
                    RobotEye(offsetX: displayedOffsetX, offsetY: displayedOffsetY, eyeSize: displayedEyeSize, expression: expression, side: .left, color: eyeColor)
                        .onTapGesture { onEyesTapped() }
                    RobotEye(offsetX: displayedOffsetX, offsetY: displayedOffsetY, eyeSize: displayedEyeSize, expression: expression, side: .right, color: eyeColor)
                        .onTapGesture { onEyesTapped() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onChange(of: commandManager.currentCommand) { _, newValue in
                guard !isEmotionAnimating else { return }
                updateEyes(for: newValue)
            }
            .onChange(of: cameraManager.offsetX) { _, _ in
                guard !isEmotionAnimating else { return }
                followIndexFinger()
            }
            .onChange(of: cameraManager.offsetY) { _, _ in
                guard !isEmotionAnimating else { return }
                followIndexFinger()
            }
            .onChange(of: commandManager.isPlayingSequence) { _, isPlaying in
                isPlaying ? startEmotionAnimation() : stopEmotionAnimation()
            }
            .onChange(of: emotion) { _, _ in
                if commandManager.isPlayingSequence { startEmotionAnimation() }
            }
            .onDisappear { emotionTask?.cancel() }
        }
    }

    private var displayedOffsetX: CGFloat { isEmotionAnimating ? 0 : eyeOffsetX }
    private var displayedOffsetY: CGFloat { isEmotionAnimating ? 0 : eyeOffsetY }
    private var displayedEyeSize: CGFloat { isEmotionAnimating ? 200 : eyeSize }

    private func updateEyes(for command: String) {
        let firstChar = command.first ?? " "
        withAnimation(.smooth(duration: 0.35)) {
            switch firstChar {
            case "q": eyeOffsetX = horizontalCommandOffset; eyeOffsetY = 0; eyeSize = 200
            case "e": eyeOffsetX = -horizontalCommandOffset; eyeOffsetY = 0; eyeSize = 200
            case "w": eyeOffsetX = 0; eyeOffsetY = 0; eyeSize = 250
            case "s": eyeOffsetX = 0; eyeOffsetY = 0; eyeSize = 150
            default: eyeSize = 200; eyeOffsetX = 0; eyeOffsetY = 0
            }
        }
    }

    private func followIndexFinger() {
        let targetX = cameraManager.offsetX * followStrength
        let targetY = cameraManager.offsetY * followStrength
        let smoothing: CGFloat = 0.35
        withAnimation(.smooth(duration: 0.12)) {
            eyeOffsetX += (targetX - eyeOffsetX) * smoothing
            eyeOffsetY += (targetY - eyeOffsetY) * smoothing
        }
    }

    private func startEmotionAnimation() {
        emotionTask?.cancel()
        withAnimation(.smooth(duration: 0.35)) { expression = .neutral }
        emotionTask = Task { @MainActor in
            // Keep expressions shape-led: no pupils, pupil offsets, or pupil scaling.
            switch emotion.lowercased() {
            case "happiness", "happy":
                await animate([EyeExpression(scaleY: 0.96, form: .happy), EyeExpression(offsetY: -3, scaleY: 1.04, form: .happy), EyeExpression(scaleY: 0.96, form: .happy)], every: 0.7)
            case "sadness", "sad":
                await animate([EyeExpression(offsetY: 10, scaleX: 0.96, scaleY: 0.9, form: .sad), EyeExpression(offsetY: 14, scaleX: 0.93, scaleY: 0.86, form: .sad)], every: 0.9)
            case "anger", "angry":
                await animate([EyeExpression(scaleX: 1.06, scaleY: 0.9, form: .angry), EyeExpression(offsetY: 2, scaleX: 1.1, scaleY: 0.84, form: .angry), EyeExpression(scaleX: 1.06, scaleY: 0.9, form: .angry)], every: 0.45)
            case "fear", "fearful":
                await animate([EyeExpression(offsetY: -4, scaleX: 1.04, scaleY: 1.12, form: .fearful), EyeExpression(offsetY: -1, scaleX: 1.08, scaleY: 1.08, form: .fearful)], every: 0.65)
            case "disgust", "disgusted":
                await animate([EyeExpression(offsetX: 3, scaleX: 0.98, scaleY: 0.92, form: .disgusted), EyeExpression(offsetX: 5, scaleX: 0.95, scaleY: 0.88, form: .disgusted)], every: 0.8)
            case "surprise", "surprised":
                await animate([EyeExpression(offsetY: -5, scaleX: 1.12, scaleY: 1.16, form: .surprised), EyeExpression(offsetY: 0, scaleX: 1.06, scaleY: 1.1, form: .surprised)], every: 0.7)
            default:
                withAnimation(.smooth(duration: 0.4)) { expression = .neutral }
            }
        }
    }

    private func stopEmotionAnimation() {
        emotionTask?.cancel()
        emotionTask = nil
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { expression = .neutral }
        updateEyes(for: commandManager.currentCommand)
        followIndexFinger()
    }

    private func animate(_ frames: [EyeExpression], every duration: TimeInterval) async {
        while !Task.isCancelled {
            for frame in frames {
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: duration * 0.8, dampingFraction: 0.86)) {
                    expression = frame
                }
                do {
                    try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                } catch {
                    return
                }
            }
        }
    }
}

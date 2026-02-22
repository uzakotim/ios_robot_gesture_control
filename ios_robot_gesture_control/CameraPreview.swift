//
//  CameraPreview.swift
//  ios_robot_gesture_control
//
//  Created by Timur Uzakov on 14/02/26.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    
    @ObservedObject var cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = PreviewView()
        view.videoPreviewLayer.session = cameraManager.captureSession
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let preview = uiView as? PreviewView else { return }
//        preview.updateCommand(cameraManager.currentCommand)
//        preview.updateLandmarks(cameraManager.currentLandmarks)
    }
}

class PreviewView: UIView {
    private let commandLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.numberOfLines = 1
        return label
    }()
    
    private let landmarksLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.systemGreen.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 2
        layer.contentsScale = UIScreen.main.scale
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        addSubview(commandLabel)
        self.layer.addSublayer(landmarksLayer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
//        addSubview(commandLabel)
        self.layer.addSublayer(landmarksLayer)
    }
    
    func updateCommand(_ text: String) {
        commandLabel.text = text.isEmpty ? "…" : text
        setNeedsLayout()
    }
    
//    func updateLandmarks(_ normalizedPoints: [CGPoint]) {
//        guard let previewLayer = self.layer as? AVCaptureVideoPreviewLayer else { return }
//
//        let path = UIBezierPath()
//
//        for p in normalizedPoints {
//            // 🔁 Flip Y axis
//            let flippedPoint = CGPoint(x: p.x, y: 1.0 - p.y)
//
//            let layerPoint = previewLayer.layerPointConverted(
//                fromCaptureDevicePoint: flippedPoint
//            )
//
//            let circleRect = CGRect(
//                x: layerPoint.x - 3,
//                y: layerPoint.y - 3,
//                width: 6,
//                height: 6
//            )
//
//            path.append(UIBezierPath(ovalIn: circleRect))
//        }
//
//        landmarksLayer.path = path.cgPath
//    }
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        videoPreviewLayer.frame = bounds
//        landmarksLayer.frame = bounds
        
        if let connection = videoPreviewLayer.connection {
            if #available(iOS 17.0, *) {
                // Rotate to landscapeRight: 90 degrees clockwise from portrait
                if connection.isVideoRotationAngleSupported(180) {
                    connection.videoRotationAngle = 180
                }
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .landscapeRight
                }
            }
        }
        
        let padding: CGFloat = 12
        let maxWidth = bounds.width - padding * 2
        let size = commandLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        let width = min(size.width + 16, maxWidth)
        let height = max(size.height + 8, 34)
        commandLabel.frame = CGRect(
            x: (bounds.width - width) / 2,
            y: padding,
            width: width,
            height: height
        )
    }
}


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
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        videoPreviewLayer.frame = bounds
        
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
    }
}


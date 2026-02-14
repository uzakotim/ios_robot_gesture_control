//
//  CameraManager.swift
//  ios_robot_gesture_control
//
//  Created by Timur Uzakov on 14/02/26.
//

import AVFoundation
import SwiftUI
import Combine

@MainActor
class CameraManager: NSObject, ObservableObject {
    
    var captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()

    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .high
        
        // Front camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front) else {
            print("Front camera not available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // Video output (for future gesture processing)
            videoOutput.setSampleBufferDelegate(self,
                                                queue: DispatchQueue(label: "videoQueue"))
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            if let connection = videoOutput.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    // 90 degrees corresponds to landscapeRight rotation
                    if connection.isVideoRotationAngleSupported(0) {
                        connection.videoRotationAngle = 0
                    }
                } else {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .landscapeRight
                    }
                }
                
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true   // because front camera
                }
            }
            captureSession.startRunning()
            
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        // This is where you'll process frames for gesture recognition
        // Perfect place to integrate MediaPipe later
        
    }
}

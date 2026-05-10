//
//  CameraManager.swift
//  ios_robot_gesture_control
//
//  Created by Timur Uzakov on 14/02/26.
//

import AVFoundation
import SwiftUI
import Combine
import MediaPipeTasksVision
import simd
import Network


@MainActor
class CameraManager: NSObject, ObservableObject {
    
    var captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    
    @Published var currentLandmarks: [CGPoint] = []
    @Published var offsetX: CGFloat = 0
    @Published var offsetY: CGFloat = 0
    private var isInEyeControlMode = false
    private var eyeModeStabilityCounter = 0
    
    private var handLandmarker: HandLandmarker?
    private var isProcessingFrame = false

    private var commandManager: CommandManager

    init(commandManager: CommandManager) {
        self.commandManager = commandManager
        super.init()
        setupCamera()
        setupHandLandmarker()
    }

    func setupHandLandmarker() {
        do {
            let options = HandLandmarkerOptions()
            options.baseOptions.delegate = .CPU
            options.baseOptions.modelAssetPath = Bundle.main.path(
                forResource: "hand_landmarker",
                ofType: "task"
            )!
            options.runningMode = .video
            options.numHands = 1
            options.minHandDetectionConfidence = 0.5
            options.minHandPresenceConfidence = 0.5
            options.minTrackingConfidence = 0.5

            handLandmarker = try HandLandmarker(options: options)
        } catch {
            print("Failed to create HandLandmarker: \(error)")
        }
    }

    private func handleLandmarkerResult(_ result: HandLandmarkerResult) {

        guard let hand = result.landmarks.first else {
            DispatchQueue.main.async { [weak self] in
                self?.offsetX = 0
                self?.offsetY = 0
            }
            commandManager.sendCommand("k 0")
            return
        }

        // ===== HANDEDNESS (CORRECT WAY) =====
        let handedness = result.handedness.first?.first?.categoryName ?? "Unknown"
        let isRightHand = handedness == "Right"

        print("Detected hand:", handedness)
        
        // ===== POSITION =====
        let meanX = hand.map { $0.x }.reduce(0, +) / Float(hand.count)
        let correctedX = 1.0 - meanX   // because front camera is mirrored

        let position: String
        if correctedX < 0.33 {
            position = "LEFT"
        } else if correctedX < 0.66 {
            position = "MIDDLE"
        } else {
            position = "RIGHT"
        }

        // ===== PALM / BACK (NO NEED TO FLIP BASED ON HAND) =====
        let wrist = hand[0]
        let indexMCP = hand[5]
        let pinkyMCP = hand[17]

        let v1 = SIMD3<Float>(
            indexMCP.x - wrist.x,
            indexMCP.y - wrist.y,
            indexMCP.z - wrist.z
        )

        let v2 = SIMD3<Float>(
            pinkyMCP.x - wrist.x,
            pinkyMCP.y - wrist.y,
            pinkyMCP.z - wrist.z
        )

        let normal = simd_cross(v1, v2)

        // IMPORTANT:
        // In MediaPipe iOS, for front camera:
        // normal.z < 0 typically means PALM facing camera.
        let orientation = isRightHand ? normal.z < 0 ? "PALM" : "BACK" : normal.z < 0 ? "BACK" : "PALM"

        // =========================================================
        // 👆 INDEX FINGER DETECTION (ROBUST VERSION)
        // =========================================================

        let indexTip = hand[8]
        let indexPIP = hand[6]
        let middleTip = hand[12]
        let middlePIP = hand[10]
        let ringTip = hand[16]
        let ringPIP = hand[14]
        let pinkyTip = hand[20]
        let pinkyPIP = hand[18]

        func distance(_ a: NormalizedLandmark, _ b: NormalizedLandmark) -> Float {
            let dx = a.x - b.x
            let dy = a.y - b.y
            let dz = a.z - b.z
            return sqrt(dx*dx + dy*dy + dz*dz)
        }

        // Extended if tip is farther from wrist than PIP
        let indexExtended  = distance(indexTip, wrist)  > distance(indexPIP, wrist)
        let middleExtended = distance(middleTip, wrist) > distance(middlePIP, wrist)
        let ringExtended   = distance(ringTip, wrist)   > distance(ringPIP, wrist)
        let pinkyExtended  = distance(pinkyTip, wrist)  > distance(pinkyPIP, wrist)

        // Only index up
        let onlyIndexShown = indexExtended &&
                             !middleExtended &&
                             !ringExtended &&
                             !pinkyExtended

        print("Index:", indexExtended,
              "Middle:", middleExtended,
              "Ring:", ringExtended,
              "Pinky:", pinkyExtended)

        // =========================================================
        // 👀 EYE CONTROL MODE (WITH STABILITY LOCK)
        // =========================================================

        let eyeGestureDetected = onlyIndexShown && orientation == "PALM"

        // Require gesture to be stable for a few frames
        if eyeGestureDetected {
            eyeModeStabilityCounter += 1
        } else {
            eyeModeStabilityCounter -= 1
        }

        // Clamp counter
        eyeModeStabilityCounter = max(0, min(eyeModeStabilityCounter, 5))

        // Enter eye mode after 3 stable frames
        if eyeModeStabilityCounter >= 3 {
            isInEyeControlMode = true
        }

        // Exit eye mode only when gesture clearly gone
        if eyeModeStabilityCounter == 0 {
            isInEyeControlMode = false
        }

        if isInEyeControlMode {

            let correctedX = 1.0 - indexTip.x
            let correctedY = 1.0 - indexTip.y

            DispatchQueue.main.async { [weak self] in
                self?.offsetX = CGFloat(correctedX - 0.5)
                self?.offsetY = CGFloat(correctedY - 0.5)
                
            }
            mapGestureToCommand(position: "STOP", orientation: "PALM")
            return
        }
        // =========================================================
        // 🎮 MOVEMENT MODE (ALL OTHER GESTURES)
        // =========================================================

        DispatchQueue.main.async { [weak self] in
            self?.offsetX = 0
            self?.offsetY = 0
        }

        mapGestureToCommand(position: position, orientation: orientation)
    }

    private func mapGestureToCommand(position: String, orientation: String) {

        let command: String

        if position == "LEFT" {
            command = "e 170"
        }
        else if position == "RIGHT" {
            command = "q 170"
        }
        else if position == "MIDDLE" && orientation == "PALM" {
            command = "s 150"
        }
        else if position == "MIDDLE" && orientation == "BACK" {
            command = "w 150"
        }
        else {
            command = "k 0"
        }

        commandManager.sendCommand(command)
    }

    private func setupCamera() {
        captureSession.sessionPreset = .iFrame1280x720
        
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
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            
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

        guard let handLandmarker = handLandmarker else { return }

        // Prevent overlapping inference (VERY important)
        if isProcessingFrame { return }
        isProcessingFrame = true

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessingFrame = false
            return
        }

        let timestamp = Int(CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds * 1000)

        do {
            let mpImage = try MPImage(pixelBuffer: pixelBuffer)
            let result = try handLandmarker.detect(
                videoFrame: mpImage,
                timestampInMilliseconds: timestamp
            )

            handleLandmarkerResult(result)

        } catch {
            print("Detection error: \(error)")
        }

        isProcessingFrame = false
    }
}


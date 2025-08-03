//
//  CameraService.swift
//  ABCPal
//
//  Created by Nik Edmiidz on 4/12/25.
//

import AVFoundation
import UIKit

class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isSetup = false
    @Published var error: CameraError?
    
    let session = AVCaptureSession()
    var photoOutput = AVCapturePhotoOutput()
    private var photoCompletion: ((UIImage?) -> Void)?
    
    enum CameraError: Error {
        case cameraUnavailable
        case captureError
    }
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        // Request camera permissions
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    self.configureSession()
                }
            } else {
                print("Camera permission denied")
            }
        }
    }
    
    private func configureSession() {
        // Start session configuration
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Add camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Could not create camera input")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
        
        // Start the session
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSetup = true
                print("Camera session started successfully")
            }
        }
    }
    
    func takePhoto(completion: @escaping (UIImage?) -> Void) {
        print("Taking photo...")
        guard session.isRunning else {
            print("Session not running")
            completion(nil)
            return
        }
        
        self.photoCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // AVCapturePhotoCaptureDelegate method
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("Photo processing completed")
        
        if let error = error {
            print("Error capturing photo: \(error)")
            DispatchQueue.main.async {
                self.photoCompletion?(nil)
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Could not get image data")
            DispatchQueue.main.async {
                self.photoCompletion?(nil)
            }
            return
        }
        
        let image = UIImage(data: imageData)
        print("Photo captured successfully: \(image != nil)")
        
        DispatchQueue.main.async {
            self.photoCompletion?(image)
        }
    }
}
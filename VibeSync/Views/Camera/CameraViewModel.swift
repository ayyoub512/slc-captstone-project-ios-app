import SwiftUI
import AVFoundation
import Combine

class CameraViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var session = AVCaptureSession()
    @Published var capturedImage: UIImage?
    @Published var showPermissionAlert = false
    @Published var currentPosition: AVCaptureDevice.Position = .back
    
    // MARK: - Private Properties
    private var photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    func flipCamera() {
        let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        setupCamera(position: newPosition)
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = photoOutput.maxPhotoQualityPrioritization
        photoOutput.capturePhoto(with: settings, delegate: self)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }
    
    func retakePhoto() {
        capturedImage = nil
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }
    
    func sendVibe() {
        guard let image = capturedImage else {
            print("No image to send")
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data")
            return
        }
        
        print("=== SENDING IMAGE ===")
        print("Image size: \(imageData.count) bytes")
        print("Image dimensions: \(image.size)")
        print("Ready to send to a friend")
        print("=======================")
        
        // TODO: Implement backend integration for widget delivery
    }
    
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupCamera(position: AVCaptureDevice.Position = .back) {
        session.beginConfiguration()
        
        // Remove existing input
        if let currentInput = currentInput {
            session.removeInput(currentInput)
        }
        
        // Get camera device
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        // Add input
        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
            currentPosition = position
        }
        
        // Add output
        if !session.outputs.contains(photoOutput) {
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
        }
        
        // Configure session preset for quality
        session.sessionPreset = .photo
        
        session.commitConfiguration()
        
        // Start session
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("Failed to process photo data")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = image
            self?.stopSession()
        }
    }
}

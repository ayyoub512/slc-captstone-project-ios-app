import AVFoundation
import Combine
import SwiftUI

class CameraViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var session = AVCaptureSession()
    @Published var capturedImage: UIImage?
    @Published var showPermissionAlert = false // this is for when permission was denied
    @Published var askForCameraPermision = false // initial ask for permission
    @Published var currentPosition: AVCaptureDevice.Position = .back
    @Published var overlayText: String = "Hello World"
    
    // MARK: - Private Properties
    private var photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var isConfiguring = false

    // MARK: - Initialization
    override init() {
        super.init()
    }

    // MARK: - Public Methods
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            askForCameraPermision = false
            showPermissionAlert = false
            setupCamera()
        case .notDetermined:
            askForCameraPermision = true
            showPermissionAlert = false
        case .denied, .restricted:
            askForCameraPermision = true
            showPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    func askPermission(){
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.setupCamera()
                    self?.showPermissionAlert = false
                    self?.askForCameraPermision = false
                } else {
                    self?.showPermissionAlert = true
                    self?.showPermissionAlert = true
                }
            }
        }
    }

    func flipCamera() {
        let newPosition: AVCaptureDevice.Position =
            currentPosition == .back ? .front : .back
        setupCamera(position: newPosition)
    }

    func capturePhoto() {
        guard session.isRunning else {
            print("capturePhoto - Session is not running. Returning")
            return
        }
        guard let connection = photoOutput.connection(with: .video),
            connection.isActive,
            connection.isEnabled
        else {
            print("capturePhoto - Connection is not active .video")
            return
        }

        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization =
            photoOutput.maxPhotoQualityPrioritization

        print("Capturing photo...")
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func retakePhoto() {
        capturedImage = nil
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }

    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }

    private func setupCamera(position: AVCaptureDevice.Position = .back) {
        // Prevent concurrent configuration
        guard !isConfiguring else {
            print("Camera already configuring")
            return
        }

        isConfiguring = true

        // Configure on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()

            // Remove existing input
            if let currentInput = self.currentInput {
                self.session.removeInput(currentInput)
            }

            // Get camera device
            guard
                let device = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: position
                ),
                let input = try? AVCaptureDeviceInput(device: device)
            else {
                self.session.commitConfiguration()
                self.isConfiguring = false
                print("Failed to create camera input")
                return
            }

            // Add input
            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.currentInput = input

                DispatchQueue.main.async {
                    self.currentPosition = position
                }
            }

            // Add output if not already added
            if !self.session.outputs.contains(self.photoOutput) {
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }
            }

            // Configure connection orientation
            if let connection = self.photoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }

            // Configure session preset for quality
            if self.session.canSetSessionPreset(.photo) {
                self.session.sessionPreset = .photo
            }

            self.session.commitConfiguration()

            // Start session and wait for it to be ready
            if !self.session.isRunning {
                self.session.startRunning()
            }

            // Add small delay to ensure session is fully running
            // Thread.sleep(forTimeInterval: 0.3)

            self.isConfiguring = false
            print(
                "Camera configured for \(position == .back ? "back" : "front") camera"
            )
        }
    }
}



// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {

        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }

        guard let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else {
            print("Failed to process photo data")
            return
        }

        print("Photo captured successfully")

        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = image
        }

        // Stop session after capture (save battery)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        // Optional: Add capture animation/sound here
        print("Will capture photo")
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings
    ) {
        // Optional: Photo was captured (shutter moment)
        print("Did capture photo")
    }
}

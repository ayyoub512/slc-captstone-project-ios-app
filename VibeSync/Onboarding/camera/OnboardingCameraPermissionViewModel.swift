
//
//  CameraViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 16/4/2026.
//


import AVFoundation
import Combine
import SwiftUI

@Observable
class OnboardingCameraPermissionViewModel {
    var hasPermission: Bool?
    
    // MARK: - Public Methods
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasPermission = true
        case .notDetermined:
            askPermission()
            
        case .denied, .restricted:
            hasPermission = false
        @unknown default:
            hasPermission = true // just to move on with the onboarding
            break
        }
    }
    
    func askPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.hasPermission = true
                } else {
                    self?.hasPermission = false
                }
            }
        }
    }
    
    func openSettings(){
        guard
            let url = URL(
                string: UIApplication.openSettingsURLString
            )
        else { return }
        UIApplication.shared.open(url)
    }
}

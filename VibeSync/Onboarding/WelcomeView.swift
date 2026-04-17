//
//  WelcomeView.swift
//  VibeSync
//
//  Created by Ayyoub on 15/4/2026.
//

import SwiftUI

enum OnboardingStep: Hashable {
    case name
    case photo
    case cameraPermission
    case notificationPermission
}

struct WelcomeView: View {
    @State private var step: OnboardingStep = .name
    @State private var path: [OnboardingStep] = [.name]

    var body: some View {
        NavigationStack(path: $path) {

            ProfileNameSetupView {
                path.append(.photo)
            }
            .navigationDestination(for: OnboardingStep.self) { step in
                switch step {

                case .name:
                    ProfileNameSetupView {
                        path.append(.photo)
                    }

                case .photo:
                    ProfilePhotoSetupView { _ in
                        path.append(.cameraPermission)
                    }

                case .cameraPermission:
                    OnboardingCameraPermissionView {
                        path.append(.notificationPermission)
                    }

                case .notificationPermission:
                    OnboardingNotificationPermissionView{
                        
                    }
                }
            }

        }
    }
}
#Preview {
    WelcomeView()
}

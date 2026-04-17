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
    @State private var viewModel = WelcomeViewModel()
    @State private var errorMessage: String?
    
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
                    OnboardingNotificationPermissionView {
                        Task {
                            await viewModel.completeOnboarding()
                        }
                    }
                }
            }
            
            if let error = errorMessage{
                Text(error)
                    .foregroundStyle(.red)
            }

        }
        .overlay {
            if case .loading = viewModel.state {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Setting up your profile...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        
        .onChange(of: viewModel.state) { _, newState in
            switch newState {
            case .success:
                // onboarding complete → move to main app
                UserDefaults.standard.set(true, forKey: K.shared.hasOnboarded)
                Log.shared.info("[INFO: WelcomeView - onChange] User has finished onboarding")

            case .error(let message):
                Log.shared.error("[ERROR: WelcomeView - onChange]: \(message)")
                errorMessage = message

            default:
                break
            }
        }
    }
    
}
#Preview {
    WelcomeView()
}

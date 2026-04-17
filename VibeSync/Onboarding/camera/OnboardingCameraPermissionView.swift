//
//  CameraPermissionView.swift
//  VibeSync
//
//  Created by Ayyoub on 2/3/2026.
//

import SwiftUI

struct OnboardingCameraPermissionView: View {
    @State var model: OnboardingCameraPermissionViewModel =
        OnboardingCameraPermissionViewModel()

    var onContinue: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Spacer()
                .frame(height: 20)

            VStack(spacing: 12) {
                Text("Enable Camera")
                    .font(.system(size: 28, weight: .semibold))
                    .multilineTextAlignment(.center)

                Text(
                    "Allow camera access to capture and share photos with your friends"
                )
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundStyle(.brandPrimary)
                .symbolEffect(.pulse, options: .repeating)

            Spacer()

            if let hasPermission = model.hasPermission {
                if !hasPermission {
                    Button {
                        model.openSettings()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")

                            Text("Allow in settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandPrimary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

            } else {
                Button {
                    model.checkPermissions()

                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")

                        Text("Allow permission")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brandPrimary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            }
        }
        .onChange(
            of: model.hasPermission,
            { oldValue, newValue in
                if model.hasPermission == true {
                    onContinue()
                }
            }
        )

        .padding()
    }
}

#Preview {
    OnboardingCameraPermissionView {

    }.environmentObject(CameraViewModel())
}

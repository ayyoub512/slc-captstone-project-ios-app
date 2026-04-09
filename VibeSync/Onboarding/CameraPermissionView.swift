//
//  CameraPermissionView.swift
//  VibeSync
//
//  Created by Ayyoub on 2/3/2026.
//

import SwiftUI

struct CameraPermissionView: View {
    @EnvironmentObject var cameraViewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(.cyan)

            Text("Enable Camera")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Allow camera access to capture and share vibes with your friends")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer()

            // Request Permission Button
            Button{
                cameraViewModel.askPermission()
            }label: {
                Text("Allow Camera")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.glassProminent)


            // Open Settings if user previously denied notifications
            if cameraViewModel.showPermissionAlert {
                Button("Enable in Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .foregroundColor(.cyan)
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    NotificationPermissionView()
        .environmentObject(APNSNotificationsManager())
}

//
//  NotificationPermissionView.swift
//  VibeSync
//
//  Created by Ayyoub on 2/3/2026.
//

import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var notifications: APNSNotificationsManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundStyle(.cyan)

            Text("Enable Notifications")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text(
                "To receive messages and alerts from your friends, please allow notifications. You won't get updates otherwise."
            )
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)

            Spacer()

            Button(action: {
                switch notifications.authorizationStation {
                case .notDetermined:
                    Task {
                        await notifications.request()
                    }
                case .denied:
                    guard
                        let url = URL(
                            string: UIApplication.openSettingsURLString
                        )
                    else { return }
                    UIApplication.shared.open(url)

                // case .authorized, .provisional, .ephemeral:
                default:
                    Task {
                        // Save the token
                        UIApplication.shared
                            .registerForRemoteNotifications()
                        dismiss()
                    }
                }
            }) {

                Text( notifications.hasPermission ? "Allowed" : "Allow Notifications")
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.glassProminent)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    NotificationPermissionView()
        .environmentObject(APNSNotificationsManager())
}

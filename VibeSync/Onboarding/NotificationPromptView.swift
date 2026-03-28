//
//  PermissionsView.swift
//  VibeSync
//
//  Created by Ayyoub on 2/3/2026.
//

import SwiftUI

struct NotificationPromptView: View {
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

            Text("To receive messages and alerts from your friends, please allow notifications. You won't get updates otherwise.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer()

            // Request Permission Button
            Button(action: {
                Task {
                    await notifications.request()
                    if notifications.hasPermission {
                        UIApplication.shared.registerForRemoteNotifications()
                        dismiss()
                    }
                }
            }) {
                Text(notifications.hasPermission ? "Enabled" : "Allow Notifications")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.glassProminent)
            .disabled(notifications.hasPermission)

            // Open Settings if user previously denied notifications
            if !notifications.hasPermission {
                Button("Enable in Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .font(.footnote)
                .foregroundColor(.cyan)
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    NotificationPromptView()
        .environmentObject(APNSNotificationsManager())
}

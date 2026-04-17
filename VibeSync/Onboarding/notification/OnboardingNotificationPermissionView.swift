//
//  NotificationPermissionView.swift
//  VibeSync
//
//  Created by Ayyoub on 2/3/2026.
//

import SwiftUI

struct OnboardingNotificationPermissionView: View {
    @State var model = OnboardingNotificationPermissionViewModel()
    @Environment(\.scenePhase) private var scenePhase
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 20)

            VStack(spacing: 12) {
                Text("Enable Notifications")
                    .font(.system(size: 28, weight: .semibold))
                    .multilineTextAlignment(.center)

                Text(
                    "To receive messages and alerts from your friends, please allow notifications. You won't get updates otherwise."
                )
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "bell.fill")
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
                    Task {
                        await model.request()
                        await model.getAuthorizationStatus()
                    }

                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.fill")

                        Text("Allow notification")
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
                Log.shared.debug("[OnboardingNotificationPermissionView - onChange] mode.hasPermission=\(newValue, default: "")")

                if model.hasPermission == true {
                    onContinue()
                }
            }
        )
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Customer returned to app
                Task{
                    await model.getAuthorizationStatus()
                }
            }
           
        }

        .onAppear {
            Log.shared.debug(
                "[OnboardingNotificationPermissionView - getAuthorizationStatus] On appear "
            )

            Task {
                await model.getAuthorizationStatus()
            }
        }
        .padding()
    }
}

#Preview {
    OnboardingNotificationPermissionView {

    }
    .environmentObject(APNSNotificationsManager())
}

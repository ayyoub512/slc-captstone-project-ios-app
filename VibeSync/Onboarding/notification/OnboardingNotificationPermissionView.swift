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
        ZStack{
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.08),
                        Color.purple.opacity(0.05),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
            
            
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
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brandPrimary)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }else{
                        // Its all good, I will just add this button here in case
                        Button {
                            onContinue()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                
                                Text("Finish")
                            }
                            .fontWeight(.bold)
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
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandPrimary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                }
            }
            .padding()
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
       
    }
}

#Preview {
    OnboardingNotificationPermissionView {

    }
    .environmentObject(APNSNotificationsManager())
}

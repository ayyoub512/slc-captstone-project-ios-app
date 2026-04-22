//
//  RootView.swift
//  VibeSync
//
//  Created by Ayyoub on 14/4/2026.
//

import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var authManager
    @State private var navManager = NavigationManager.shared

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationManager: APNSNotificationsManager
    @Environment(NetworkMonitor.self) private var networkMonitor

    @StateObject private var keyboardManager = KeyboardManager()

    @AppStorage(K.shared.hasOnboarded) var hasSeenOnboarding: Bool = false

    var body: some View {
        Group {
            if authManager.isAuthenticated {

                if !hasSeenOnboarding {
                    WelcomeView()

                } else {
                    mainAppView
                }

            } else {
                NavigationStack {
                    SigninWithAppleView()
                }
            }
        }
        .task {
            authManager.checkCredentialStatus(modelContext: modelContext)
        }
        .environment(navManager)
        .environmentObject(keyboardManager)

    }

    var mainAppView: some View {
        TabView(selection: $navManager.selectedTab) {
            NavigationStack(path: $navManager.profilePath) {
                ProfileView()
            }
            .tag(0)

            NavigationStack {
                CameraView()
            }
            .tag(1)

            NavigationStack(path: $navManager.inboxPath) {
                InboxView()

            }
            .tag(2)

        }
        .onChange(of: navManager.selectedTab) { _, _ in
            keyboardManager.dismiss()
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .simultaneousGesture(
            navManager.canSwipeTabs ? nil : DragGesture()
        )
        .background(
            PageSwipeController(isEnabled: navManager.canSwipeTabs)
        )
        .overlay(alignment: .top) {
            if !networkMonitor.isConnected {
                offlineBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(
                        .spring(response: 0.4),
                        value: networkMonitor.isConnected
                    )
                    .padding(.top, 56)  // clears the status bar
            }
        }
    }

    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 13, weight: .medium))
            Text("No internet connection")
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color.primary.opacity(0.85), in: Capsule())
    }
}

#Preview {
    RootView()
}

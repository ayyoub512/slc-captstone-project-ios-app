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

    var body: some View {
        Group {
            if authManager.isAuthenticated {
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
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .simultaneousGesture(
                    navManager.canSwipeTabs ? nil : DragGesture()
                )
                .background(
                    PageSwipeController(isEnabled: navManager.canSwipeTabs)
                )

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

    }
}

#Preview {
    RootView()
}

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

    @StateObject private var keyboardManager = KeyboardManager()
    
    @AppStorage(K.shared.hasOnboarded) var hasSeenOnboarding: Bool = false
    
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                
                if !hasSeenOnboarding{
                    WelcomeView()
                    
                }else{
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
    }
}



#Preview {
    RootView()
}

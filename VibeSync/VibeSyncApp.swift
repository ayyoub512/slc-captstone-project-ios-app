//
//  VibeSyncApp.swift
//  VibeSync
//
//  Created by Ayyoub on 11/2/2026.
//

import OSLog
import SwiftData
import SwiftUI
import UserNotifications
import AuthenticationServices


@main
struct VibeSyncApp: App {
    @UIApplicationDelegateAdaptor private var vibeSyncDelegate: VibeSyncDelegate
    @State private var authManager = AuthService.shared
    @StateObject private var notificationManager = APNSNotificationsManager()
    @State private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authManager)
                .environment(appState)
                .environmentObject(notificationManager)
        }
        .modelContainer(for: [FriendModel.self])
    }
}



@Observable
class VibeSyncDelegate: NSObject, UIApplicationDelegate {
    var notificationManager = APNSNotificationsManager()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        // TODO: I must ensure that I get the authorization to send notification from user FIRST before doing this
        UIApplication.shared.registerForRemoteNotifications()

        AppState.shared.triggerFriendRefresh() // trigger refresh on app launch
        
        return true
    }

    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in
            String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()

        notificationManager.saveAPN(with: token)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error
    ) {
        Log.shared.error(
            "[ERROR: VibeSyncApp - VibeSyncDelegate] Error didFailToRegisterForRemoteNotificationsWithError : \(error)"
        )
    }
}

extension VibeSyncDelegate: UNUserNotificationCenterDelegate {
    
    // User taps on the notification (app was in the background or closed)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        AppState.shared.triggerFriendRefresh()
        NavigationManager.shared.goToTab(id: 2)
    }

    // App is in the foreground when the notification arrived
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        
        // Trigger a refresh on notification
        AppState.shared.triggerFriendRefresh()
        
        return [.banner, .sound, .badge]
    }
}

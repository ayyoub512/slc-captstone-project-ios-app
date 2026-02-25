//
//  VibeSyncApp.swift
//  VibeSync
//
//  Created by Ayyoub on 11/2/2026.
//

import SwiftUI
import UserNotifications

@Observable
class VibeSyncDelegate: NSObject, UIApplicationDelegate {
    var notificationManager = NotificationsManager()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        // TODO: I must ensure that I get the authorization to send notification from user FIRST before doing this
        UIApplication.shared.registerForRemoteNotifications()

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
        print("App didRegisterForRemoteNotificationsWithDeviceToken: \(token)")
        
        notificationManager.saveAPN(with: token)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error
    ) {
        print("Error didFailToRegisterForRemoteNotificationsWithError : \(error)")
        print(error)
    }
}

extension VibeSyncDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        print(response.notification.request.content)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }
}

@main
struct VibeSyncApp: App {
    @StateObject var authentication = AuthService()
    
    // Notification
    @UIApplicationDelegateAdaptor private var vibeSyncDelegate: VibeSyncDelegate

    var body: some Scene {
        WindowGroup {
            if authentication.isAuthenticated {
                DrawingView()
                    .environmentObject(authentication)
            } else {
                LoginView()
                    .environmentObject(authentication)

                RegisterView()
                    .environmentObject(authentication)

            }
        }
    }
}

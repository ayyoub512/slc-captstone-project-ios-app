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
    // Notification
    @UIApplicationDelegateAdaptor private var vibeSyncDelegate: VibeSyncDelegate

    @StateObject var authentication = AuthService()
    @State private var navManager = NavigationManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authentication.isAuthenticated {
                    TabView(selection: $navManager.selectedTab) {
                        // page 1
                        DrawingView()
                            .tag(0)
                        
                        // page 2
                        NavigationStack(path: $navManager.inboxPath){
                            InboxView()
                        }
                        .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea()
                    
                } else {
                    LoginView()
                        .environmentObject(authentication)
                }
            }
            .environment(navManager)
            .environmentObject(authentication)
            .onOpenURL { url in
                // TODO: Handle deep link
                print("Opened a new url \(url.absoluteString) ")
            }
        }
    }
}

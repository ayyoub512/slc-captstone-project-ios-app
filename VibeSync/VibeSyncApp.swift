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

@Observable
class VibeSyncDelegate: NSObject, UIApplicationDelegate {
    var notificationManager = APNSNotificationsManager()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Log.shared.info("didFinishLaunchingWithOptions")
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
        Log.shared.info(
            "App didRegisterForRemoteNotificationsWithDeviceToken: \(token)"
        )

        notificationManager.saveAPN(with: token)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error
    ) {
        Log.shared.info(
            "Error didFailToRegisterForRemoteNotificationsWithError : \(error)"
        )
        Log.shared.info("Error: \(error)")
    }
}

extension VibeSyncDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        Log.shared.info("UNUserNotificationCenterDelegate didReceive")
        Log.shared.info("\(response.notification.request.content)")
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        Log.shared.info(
            "UNUserNotificationCenterDelegate userNotificationCenter"
        )
        return [.banner, .sound, .badge]
    }
}

@main
struct VibeSyncApp: App {
    
    // Notification
    @UIApplicationDelegateAdaptor private var vibeSyncDelegate: VibeSyncDelegate

    @State var authentication = AuthService.shared
    @State private var navManager = NavigationManager()

    @StateObject private var notificationManager = APNSNotificationsManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if authentication.isAuthenticated {

                    TabView(selection: $navManager.selectedTab) {

                        NavigationStack(path: $navManager.profilePath) {
                            ProfileView()
                        }
                        .tag(0)

                        CameraView()
                            .tag(1)
                            .environmentObject(notificationManager)

                        NavigationStack(path: $navManager.inboxPath) {
                            InboxView()

                        }
                        .tag(2)

                    }

                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea()

                } else {
                    NavigationStack {
//                        AuthContainerView()
                        SigninWithAppleView()
                    }
                }
            }
            .task {
                authentication.checkCredentialStatus()
            }
//            .onReceive(NotificationCenter.default.publisher(for: ASAuthorizationAppleIDProvider.credentialRevokedNotification), perform: { _ in
//                Log.shared.error("Crednetial Revoked")
//                UserDefaults.standard.removeObject(forKey: K.shared.appleUserId)
//            })
            .environment(navManager)
            .environmentObject(notificationManager)
            .modelContainer(for: [FriendModel.self])
            .onOpenURL { url in
                // TODO: Handle notification deep link
                Log.shared.info("Opened a new url \(url.absoluteString) ")
            }

        }
    }
}

//
//  OnboardingNotificationPermissionViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 17/4/2026.
//

import Combine
import Foundation
import KeychainSwift
import UIKit
import UserNotifications

// TODO: refactore so there is uses the already made APNsnotifixationmanager class
@Observable
class OnboardingNotificationPermissionViewModel {
    private(set) var hasPermission: Bool?
    private(set) var authorizationStation: UNAuthorizationStatus?

    private let keyChain = KeychainSwift()

    init() {
        Task {
            await getAuthorizationStatus()
        }
    }

    func request() async {
        do {
            self.hasPermission = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            Log.shared.error("Error: \(error)")
        }
    }

    func getAuthorizationStatus() async {
        let status =
            await UNUserNotificationCenter
            .current()
            .notificationSettings()

        authorizationStation = status.authorizationStatus

        switch status.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            hasPermission = true
        case .denied:
            hasPermission = false
        case .notDetermined:
            break

        default:
            hasPermission = false
        }
    }

    func openSettings() {
        guard
            let url = URL(
                string: UIApplication.openSettingsURLString
            )
        else { return }
        UIApplication.shared.open(url)
    }
}

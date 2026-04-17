//
//  NotificationsManager.swift
//  VibeSync
//
//  Created by Ayyoub on 15/2/2026.
//

import Combine
import Foundation
import KeychainSwift
import UserNotifications
import UIKit

@MainActor
class APNSNotificationsManager: ObservableObject {
    @Published private(set) var hasPermission: Bool = true
    @Published private(set) var authorizationStation: UNAuthorizationStatus = .notDetermined
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
        let status = await UNUserNotificationCenter
            .current()
            .notificationSettings()
        
        authorizationStation = status.authorizationStatus
        
        switch status.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            hasPermission = true
        default:
            hasPermission = false
        }
    }

    // TODO - Debug why this error happens
    // Where it says its saved but db doesnt have it for new users
    func saveAPN(with apn: String) {
        self.sendDeviceTokenToServer(with: apn)
        keyChain.set(apn, forKey: K.shared.keychainAPNKey)
    }

    func hasAPNsChanged(with token: String) -> Bool {
        return keyChain.get(K.shared.keychainAPNKey) != token
    }
    
    /// Send APNS token to server
    func sendDeviceTokenToServer(with token: String) {
        // Let's make sure it hasn't change yet
        Log.shared.info("Saving app push notification token to server")

        guard let url = URL(string: K.shared.registerDeviceURL)
        else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let jwtToken = keyChain.get(K.shared.keyChainUserTokenKey) else {
            Log.shared.info(
                "No jwt token is stored in chain to be used for APNs server device registeration"
            )
            return
        }
        request.addValue(
            "Bearer \(jwtToken)",
            forHTTPHeaderField: "Authorization"
        )

        let body: [String: Any] = [
            "deviceToken": token,
            "isWidget": false
        ]
        
        request.httpBody = try? JSONSerialization.data(
            withJSONObject: body,
            options: []
        )

        URLSession.shared.dataTask(with: request) { data, response, error in
            Log.shared.info("sendDeviceTokenToServer Request was made")
            if let error = error {
                Log.shared.error("Error sending device token: \(error)")
                return
            }

            if let response = response as? HTTPURLResponse {
                Log.shared.info("Device token sent. Status code: \(response.statusCode)")
            }
        }.resume()
    }

}


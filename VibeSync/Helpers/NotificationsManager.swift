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

@MainActor
class NotificationsManager: ObservableObject {
    @Published private(set) var hasPermission = false
    private let keyChain = KeychainSwift()

    init() {
        Task {
            await getAuthStatus()
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

    func getAuthStatus() async {
        let status = await UNUserNotificationCenter.current()
            .notificationSettings()
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
        
//        if hasAPNsChanged(with: apn) {
//            // Either first app run, or APNs has indeed changed.
//            print("New APN! Lets save it")
//            keyChain.set(apn, forKey: K.shared.keychainAPNKey)
//            self.sendDeviceTokenToServer(with: apn)
//            
//        } else {
//            print("APN hasn't changed since last time it was saved")
//        }

    }

    func hasAPNsChanged(with token: String) -> Bool {
        return keyChain.get(K.shared.keychainAPNKey) != token
    }

    
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

    
    /// Send a push notification
    func sendTestNotification(to recepientId: Int) {
            // Hard-coded user ID (for testing)
//            let userId = 9
            
            guard let url = URL(string: K.shared.sendNotificatioURL) else {
                Log.shared.error("Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Use stored JWT for authorization
            guard let jwtToken = keyChain.get(K.shared.keyChainUserTokenKey) else {
                Log.shared.error("ERROR: No JWT token found") // TODO: Go to login
                return
            }
            request.addValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
            
            // The notification payload
            let body: [String: Any] = [
                "title": "Hello User \(recepientId)",
                "body": "This is a test push notification"
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    Log.shared.error("Error sending notification: \(error)")
                    return
                }
                
                if let response = response as? HTTPURLResponse {
                    Log.shared.info("Notification request sent. Status code: \(response.statusCode)")
                }
                
                if let data = data,
                   let responseBody = try? JSONSerialization.jsonObject(with: data) {
                    Log.shared.info("Response body: \(responseBody)")
                }
            }.resume()
        }
    
}

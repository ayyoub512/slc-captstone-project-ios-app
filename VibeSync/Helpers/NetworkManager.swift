//
//  InboxViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 25/2/2026.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class NetworkManager: ObservableObject {

    @Published var friends: [Friend] = []
    @Published var working = false
    @Published var errorMessage: String?
    @Published var success: Bool?

    private var lastFetchTime: Date?
    private let cacheValidityDuration: TimeInterval = 300  // 5 minutes

    // Check if cached data is still valid
    // Cach is used the cash the fetched friends list
    private var isCacheValid: Bool {
        guard let lastFetch = lastFetchTime else { return false }
        return Date().timeIntervalSince(lastFetch) < cacheValidityDuration
    }

    // Clear cache (call when user logs out or manually refreshes)
    func clearCache() {
        friends = []
        lastFetchTime = nil
    }

    func fetchFriends(token: String, forceRefresh: Bool = false) async {
        Log.shared.info("networkmanager.fetchFriends")
        // Return cached data if still valid
        if !forceRefresh && isCacheValid && !friends.isEmpty {
            Log.shared.info("Using cached friends list")
            return
        }
        // Otherwise fetch fresh data

        guard let friendsListURL = URL(string: K.shared.friendsListURL) else {
            Log.shared.error("networkmanager.fetchFriends - Invalide URL configuration")
            self.errorMessage = "Invalide URL configuration"
            return
        }

        working = true
        errorMessage = nil

        do {
            // Setting up the request
            var request = URLRequest(url: friendsListURL)
            request.httpMethod = "GET"
            request.addValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.addValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )

            // Using await to perform the request
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            // Checking errors (e.g,  401)
            if let httpResponse = response as? HTTPURLResponse,
                !(200...299).contains(httpResponse.statusCode)
            {
                self.errorMessage = "Server error: \(httpResponse.statusCode)"
                Log.shared.error(errorMessage ?? "Error fetch friends")
                working = false
                return
            }

            // Decoding
            let decodedResponse = try JSONDecoder().decode(
                FriendListResponse.self,
                from: data
            )

            //Updating UI
            self.friends = decodedResponse.friends
        
            for friend in friends{
                Log.shared.debug("Friend: \(friend.name)")
            }
            
        } catch {
            Log.shared.error("Fetch Friends error: \(error)")
            self.errorMessage = "Failed to load friends"
        }

        working = false
    }

    /// Send vibe to friends
    func sendVibe(
        to recipients: [String],
        with jwtToken: String,
        image: UIImage
    ) async {
        guard let url = URL(string: K.shared.sendNotificatioURL) else {
            Log.shared.error(" Invalid URL")
            self.errorMessage = "Invalid server URL"
            self.working = false
            return
        }

        self.working = true
        self.errorMessage = nil

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue(
                "Bearer \(jwtToken)",
                forHTTPHeaderField: "Authorization"
            )

            // Multipart/form-data boundary
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue(
                "multipart/form-data; boundary=\(boundary)",
                forHTTPHeaderField: "Content-Type"
            )

            var bodyData = Data()

            //  Add receivers as JSON array
            do {
                let receiversJSON = try JSONSerialization.data(
                    withJSONObject: recipients,
                    options: []
                )

                bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
                bodyData.append(
                    "Content-Disposition: form-data; name=\"receivers\"\r\n"
                        .data(using: .utf8)!
                )
                bodyData.append(
                    "Content-Type: application/json\r\n\r\n".data(using: .utf8)!
                )
                bodyData.append(receiversJSON)
                bodyData.append("\r\n".data(using: .utf8)!)

                Log.shared.info(
                    "Sending to \(recipients.count) recipients: \(recipients)"
                )
            } catch {
                Log.shared.error("Failed to serialize receivers: \(error)")

                self.errorMessage = "Failed to prepare recipients data"
                self.working = false
                self.success = false

                return
            }

            // Add image
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
                bodyData.append(
                    "Content-Disposition: form-data; name=\"image\"; filename=\"vibe.jpg\"\r\n"
                        .data(using: .utf8)!
                )
                bodyData.append(
                    "Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!
                )
                bodyData.append(imageData)
                bodyData.append("\r\n".data(using: .utf8)!)

                Log.shared.info("Image size: \(imageData.count) bytes")
            } else {
                Log.shared.error("Failed to convert image to JPEG")
                await MainActor.run {
                    self.errorMessage = "Failed to process image"
                    self.working = false
                    self.success = false
                }
                return
            }

            // End boundary
            bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = bodyData

            // Send request
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            if let httpResponse = response as? HTTPURLResponse {
                Log.shared.info("Status code: \(httpResponse.statusCode)")

                if (200...299).contains(httpResponse.statusCode) {
                    if let responseBody = try? JSONSerialization.jsonObject(
                        with: data
                    ) {
                        Log.shared.info("Response: \(responseBody)")
                    }

                    self.success = true
                    self.working = false

                } else {
                    if let responseBody = try? JSONSerialization.jsonObject(
                        with: data
                    ) {
                        Log.shared.error("Error response: \(responseBody)")
                    }

                    self.errorMessage =
                        "Server error: \(httpResponse.statusCode)"
                    self.success = false
                    self.working = false

                }
            }

        } catch {
            Log.shared.info("Send vibe error: \(error)")

            self.errorMessage =
                "Failed to send vibe: \(error.localizedDescription)"
            self.success = false
            self.working = false

        }
    }

    func addFriend(with inviteCode: String, token: String) async {
        guard let addFriendsURL = URL(string: K.shared.addFriendURL) else {
            Log.shared.info(
                "addFriend(with inviteCode error: K.shared.addFriendURL is not found"
            )
            self.working = false
            self.success = false
            self.errorMessage = "Error adding friend, please try again later!"
            return
        }

        self.working = true
        self.errorMessage = nil
        self.success = nil
        
        do {
            // Setting up the request
            var request = URLRequest(url: addFriendsURL)
            request.httpMethod = "POST"
            request.addValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.addValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )

            let body: [String: Any] = [
                "inviteCode": inviteCode
            ]
            
            request.httpBody = try? JSONSerialization.data(
                withJSONObject: body,
                options: []
            )
            
            // Using await to perform the request
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            // Checking errors (e.g,  401)
            if let httpResponse = response as? HTTPURLResponse,
                !(200...299).contains(httpResponse.statusCode)
            {
                Log.shared.error("Server error: \(httpResponse.statusCode)")
                self.errorMessage = "Server error: \(httpResponse.statusCode)"
                self.working = false
                self.success = false
                return
            }

            // Decoding
            let decodedResponse = try JSONDecoder().decode(
                AddFriendResponse.self,
                from: data
            )

            //Updating UI
            self.working = false
            if decodedResponse.success ?? false {
                self.errorMessage = nil
                self.success = true
            }else{
                self.errorMessage = decodedResponse.message
                self.success = false
            }

        } catch {
            Log.shared.error("Fetch Friends error: \(error)")
            self.errorMessage = "Failed to add friend: \(error.localizedDescription)"
            self.success = false
            self.working = false
        }

        working = false
    }
}

struct Friend: Codable, Identifiable, Hashable {
    var id: String { _id }  // Map MongoDB _id to SwiftUI id
    let _id: String
    let name: String
    let email: String
}

struct FriendListResponse: Codable {
    let message: String
    let friends: [Friend]
}

struct AddFriendResponse: Codable {
    let message: String?
    let success: Bool?
}

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
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var sendingVibe = false
    @Published var sendSuccess: Bool?

    private var lastFetchTime: Date?
    private let cacheValidityDuration: TimeInterval = 300  // 5 minutes

    // Check if cached data is still valid
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
        // Return cached data if still valid
        if !forceRefresh && isCacheValid && !friends.isEmpty {
            print("Using cached friends list")
            return
        }
        // Otherwise fetch fresh data

        guard let friendsListURL = URL(string: K.shared.friendsListURL) else {
            self.errorMessage = "Invalide URL configuration"
            return
        }

        isLoading = true
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
                isLoading = false
                return
            }

            // Decoding
            let decodedResponse = try JSONDecoder().decode(
                FriendListResponse.self,
                from: data
            )

            //Updating UI
            self.friends = decodedResponse.friends
        } catch {
            print("Fetch Friends error: \(error)")
            self.errorMessage = "Failed to load friends"
        }

        isLoading = false
    }

    /// Send vibe to friends
    func sendVibe(
        to recipients: [String],
        with jwtToken: String,
        image: UIImage
    ) async {
        guard let url = URL(string: K.shared.sendNotificatioURL) else {
            print(" Invalid URL")

            self.errorMessage = "Invalid server URL"
            self.sendSuccess = false

            return
        }

        self.sendingVibe = true
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

                print(
                    "Sending to \(recipients.count) recipients: \(recipients)"
                )
            } catch {
                print("Failed to serialize receivers: \(error)")

                self.errorMessage = "Failed to prepare recipients data"
                self.sendingVibe = false
                self.sendSuccess = false

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

                print("Image size: \(imageData.count) bytes")
            } else {
                print("Failed to convert image to JPEG")
                await MainActor.run {
                    self.errorMessage = "Failed to process image"
                    self.sendingVibe = false
                    self.sendSuccess = false
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
                print("Status code: \(httpResponse.statusCode)")

                if (200...299).contains(httpResponse.statusCode) {
                    if let responseBody = try? JSONSerialization.jsonObject(
                        with: data
                    ) {
                        print("Response: \(responseBody)")
                    }

                    self.sendSuccess = true
                    self.sendingVibe = false

                } else {
                    if let responseBody = try? JSONSerialization.jsonObject(
                        with: data
                    ) {
                        print("Error response: \(responseBody)")
                    }

                    self.errorMessage =
                        "Server error: \(httpResponse.statusCode)"
                    self.sendSuccess = false
                    self.sendingVibe = false

                }
            }

        } catch {
            print("Send vibe error: \(error)")

            self.errorMessage =
                "Failed to send vibe: \(error.localizedDescription)"
            self.sendSuccess = false
            self.sendingVibe = false

        }
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

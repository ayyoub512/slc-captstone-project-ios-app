//
//  SendVibeSheetViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 11/3/2026.
//

import Combine
import SwiftData
import SwiftUI

class SendVibeSheetViewModel: ObservableObject {
    @Published var working = false
    @Published var errorMessage: String?
    @Published var success: Bool?

    @AppStorage("lastFetchedFriends") var lastTimeFetchedFriends: Double = Date
        .now.timeIntervalSince1970

    let token: String = {
        return KeyChainManager.shared.get(key: K.shared.keyChainUserTokenKey)
    }()

    func fetchFriends(modelContext: ModelContext) async {
        Log.shared.info("Fetching friends from API")
        guard let friendsListURL = URL(string: K.shared.friendsListURL) else {
            return
        }
        self.working = true
        defer {
            self.working = false
        }

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
            let (data, _) = try await URLSession.shared.data(
                for: request
            )

            let decodedResponse = try JSONDecoder().decode(
                FriendListResponse.self,
                from: data
            )

            // Before saving lets clear the cache
            try modelContext.delete(model: FriendModel.self)

            // decodedResponse.friends.forEach { modelContext.insert($0)}
            for friend in decodedResponse.friends {
                let descriptor = FetchDescriptor<FriendModel>(
                    predicate: #Predicate { $0._id == friend._id }
                )

                if let existing = try modelContext.fetch(descriptor).first {
                    existing.name = friend.name
                    existing.email = friend.email
                } else {
                    modelContext.insert(friend)
                }
            }

            lastTimeFetchedFriends = Date.now.timeIntervalSince1970

        } catch let error {
            Log.shared.error("Fetch Friends error: \(error)")
        }
    }
    
    
    /// Send vibe to friends
    func sendVibe(
        to recipients: [String],
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
                "Bearer \(token)",
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

    func hasCacheExceededLimit() -> Bool {
        let timeLimit: TimeInterval = 500  // 5 min
        return Date.now.timeIntervalSince1970 - lastTimeFetchedFriends >= timeLimit
    }

}

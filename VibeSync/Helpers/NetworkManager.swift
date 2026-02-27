//
//  InboxViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 25/2/2026.
//

import Combine
import Foundation

@MainActor
class NetworkManager: ObservableObject {

    @Published var friends: [Friend] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

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

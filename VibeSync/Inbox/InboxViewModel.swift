//
//  InboxViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 9/3/2026.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class InboxViewModel {
    var working = false
    var errorMessage: String?
    var success: Bool?

    //    @AppStorage(K.shared.appStorageLastFetchedFriends) var lastTimeFetchedFriends: Double = Date.now.timeIntervalSince1970
    var lastTimeFetchedFriends: Double {
        get {
            access(keyPath: \.lastTimeFetchedFriends)
            return UserDefaults.standard.double(forKey: "lastFetchedFriends")
        }
        set {
            withMutation(keyPath: \.lastTimeFetchedFriends) {
                UserDefaults.standard.set(
                    newValue,
                    forKey: "lastFetchedFriends"
                )
            }
        }
    }

    let token: String = {
        return KeyChainManager.shared.get(key: K.shared.keyChainUserTokenKey)
    }()

    func fetchFriends(modelContext: ModelContext) async {
        Log.shared.info(
            "[INFO: InboxViewModel - fetchFriends] Fetching friends from API"
        )
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

            let decoded = try JSONDecoder().decode(
                FriendListResponse.self,
                from: data
            )

            // Upserting
            for friend in decoded.friends {
                let descriptor = FetchDescriptor<FriendModel>(
                    predicate: #Predicate { $0._id == friend._id }
                )

                if let existing = try modelContext.fetch(descriptor).first {
                    existing.name = friend.name
                    existing.resizedProfileImage = friend.resizedProfileImage
                    existing.unreadCount = friend.unreadCount
                    existing.lastMessageAt = friend.lastMessageAt
                } else {
                    modelContext.insert(friend)
                }
            }
            Log.shared.info("[INFO: InboxViewModel - fetchFriends] friends: \(decoded.friends.count)")

            lastTimeFetchedFriends = Date.now.timeIntervalSince1970

        } catch let error {
            Log.shared.error("[ERROR: InboxViewModel - fetchFriends] Fetch Friends error: \(error)")
            errorMessage = "Failed to load friends"
        }
    }

    func hasCacheExceededLimit() -> Bool {
        let timeLimit: TimeInterval = K.shared.cachFriendsDurationSeconds
        return Date.now.timeIntervalSince1970 - lastTimeFetchedFriends
            >= timeLimit
    }

    func markAsRead(friendID: String) async {
        
        guard let url = URL(string: K.shared.markConversationReadURL) else {
            return
        }
        let token = KeyChainManager.shared.get(
            key: K.shared.keyChainUserTokenKey
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(["friendID": friendID])

        _ = try? await URLSession.shared.data(for: request)
    }

}

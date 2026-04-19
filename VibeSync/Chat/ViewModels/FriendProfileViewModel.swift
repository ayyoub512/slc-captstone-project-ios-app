//
//  FriendProfileViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 19/4/2026.
//

import Foundation

@Observable
class FriendProfileViewModel {
    /*
     let messageCount: Int
     let friendSince: String
     */
    private let friendId: String
    var state: LoadingState = .idle

    private(set) var name: String?
    private(set) var profileImageURL: URL?
    private(set) var profileResizedImageURL: URL?
    private(set) var messageCount: Int?
    private(set) var friendSince: String?

    init(for friendId: String) {
        self.friendId = friendId

        fetchFriend()
    }

    private func fetchFriend() {
        Task {
            await loadFriend()
        }
    }

    private func loadFriend() async {
        state = .loading

        Log.shared.info(
            "[INFO: FriendPorfileViewModel - loadFriend] Loading profile info for friend \(friendId)"
        )

        do {
            let token = KeyChainManager.shared.get(
                key: K.shared.keyChainUserTokenKey
            )

            guard let url = URL(string: K.shared.getFriendshipProfileURL) else {
                state = .error("Invalid URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )

            let body = [
                "friendID": friendId
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let http = response as? HTTPURLResponse else {
                state = .error("Invalid response")
                return
            }

            guard (200...299).contains(http.statusCode) else {
                state = .error("Server error: \(http.statusCode)")
                return
            }

            // 2. Decode JSON
            let decoded = try JSONDecoder().decode(
                FriendProfileResponse.self,
                from: data
            )

            await MainActor.run {
                self.name = decoded.name
                self.messageCount = decoded.messageCount
                self.friendSince = decoded.friendSince

                self.profileImageURL = decoded.profileImageURL
                self.profileResizedImageURL = decoded.profileResizedImageURL

                self.state = .success
            }

        } catch {
            state = .error(error.localizedDescription)
            Log.shared.error(
                "[ERROR: FriendPorfileViewModel - loadFriend] error: \(error)"
            )
        }
    }

    func removeFriend() async {
        state = .loading
        Log.shared.info(
            "[INFO: FriendProfileViewModel removeFriend] Removing friend"
        )

        do {
            let token = KeyChainManager.shared.get(
                key: K.shared.keyChainUserTokenKey
            )

            guard let url = URL(string: K.shared.removeFriendURL) else {
                state = .error("Invalid URL")
                Log.shared.error(
                    "[INFO: FriendProfileViewModel removeFriend] Invalid URL"
                )
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )

            let body = ["friendID": friendId]

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            Log.shared.info(
                "[INFO: FriendProfileViewModel removeFriend] making request \( K.shared.removeFriendURL)"
            )
            let (_, response) = try await URLSession.shared.data(for: request)

            
            Log.shared.info(
                "[INFO: FriendProfileViewModel request was made"
            )

            guard let http = response as? HTTPURLResponse,
                (200...299).contains(http.statusCode)
            else {
                if let http = response as? HTTPURLResponse {
                    state = .error(
                        "Failed to remove friend [code: \(http.statusCode)]"
                    )
                } else {
                    state = .error("Failed to remove friend")
                }
                
                Log.shared.error("[ERROR: FriendProfileViewModel removeFriend] Status code is bad")
                return
            }
            Log.shared.info("[INFO: FriendProfileViewModel removeFriend] all is good")

            state = .success

        } catch {
            state = .error(error.localizedDescription)
            Log.shared.error(
                "[ERROR: FriendProfileViewModel removeFriend] error: \(error)"
            )

        }
    }

}

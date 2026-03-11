//
//  InboxViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 9/3/2026.
//

import Combine
import SwiftData
import SwiftUI

class InboxViewModel: ObservableObject {
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

    func hasCacheExceededLimit() -> Bool {
        let timeLimit: TimeInterval = 500  // 5 min
        return Date.now.timeIntervalSince1970 - lastTimeFetchedFriends >= timeLimit
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
    let friends: [FriendModel]
}

@Model
class FriendModel: Codable {
    @Attribute(.unique)
    var _id: String
    var id: String { _id }  // Map MongoDB _id to SwiftUI id

    @Attribute var name: String
    @Attribute var email: String

    init(id: String, name: String, email: String) {
        self._id = id
        self.name = name
        self.email = email
    }

    // Codable
    enum CodingKeys: String, CodingKey {
        case _id
        case name
        case email
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: ._id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
    }
}

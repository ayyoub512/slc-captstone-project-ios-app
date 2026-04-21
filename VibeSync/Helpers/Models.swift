//
//  Models.swift
//  VibeSync
//
//  Created by Ayyoub on 11/3/2026.
//

import Foundation
import SwiftData
// Buttons style -- placing it here for now
import SwiftUI

struct Friend: Codable, Identifiable, Hashable {
    var id: String { _id }  // Map MongoDB _id to SwiftUI id
    let _id: String
    let name: String
    let email: String
    let imageURL: String?
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
    var name: String
    var resizedProfileImage: String?
    var unreadCount: Int
    var lastMessageAt: Date?

    init(
        id: String,
        name: String,
        resizedProfileImage: String? = nil,
        unreadCount: Int = 0,
        lastMessageAt: Date? = nil
    ) {
        self._id = id
        self.name = name
        self.resizedProfileImage = resizedProfileImage
        self.unreadCount = unreadCount
        self.lastMessageAt = lastMessageAt
    }

    // Codable
    enum CodingKeys: String, CodingKey {
        case _id, name, resizedProfileImage, unreadCount, lastMessageAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        name = try container.decode(String.self, forKey: .name)
        resizedProfileImage = try container.decodeIfPresent(
            String.self,
            forKey: .resizedProfileImage
        )
        unreadCount =
            try container.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0

        // Decode ISO8601 date string from MongoDB
        if let dateString = try container.decodeIfPresent(
            String.self,
            forKey: .lastMessageAt
        ) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [
                .withInternetDateTime, .withFractionalSeconds,
            ]
            lastMessageAt = formatter.date(from: dateString)
        } else {
            lastMessageAt = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: ._id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(
            resizedProfileImage,
            forKey: .resizedProfileImage
        )
        try container.encode(unreadCount, forKey: .unreadCount)
        try container.encodeIfPresent(lastMessageAt, forKey: .lastMessageAt)

    }

}

struct AddFriendResponse: Codable {
    let message: String?
    let success: Bool?
}

struct VibeMessage: Codable, Identifiable, Hashable {
    var id: String { _id }
    let _id: String
    let senderID: String
    let receiverID: String
    let imageURL: String
    let resizedImageURL: String
    let createdAt: String  // MongoDB date string
    let updatedAt: String
}

struct MessageResponse: Codable {
    let message: String
    let messages: [VibeMessage]
}

// Get friend's profile response /friendship-profile
struct FriendProfileResponse: Codable {
    let id: String
    let name: String?
    let profileImageURL: URL?
    let profileResizedImageURL: URL?
    let messageCount: Int
    let friendSince: String
}

/// Profile
struct ProfileResponse: Codable {
    let name: String?
    let email: String?
    let profileImageURL: String?
    let profileResizedImageURL: String?
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}


extension Date {
    func formattedRelative(to reference: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: reference)
    }
}

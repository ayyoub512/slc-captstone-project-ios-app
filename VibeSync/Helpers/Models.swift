//
//  Models.swift
//  VibeSync
//
//  Created by Ayyoub on 11/3/2026.
//

import Foundation
import SwiftData

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

    init(id: String, name: String, resizedProfileImage: String?) {
        self._id = id
        self.name = name
        self.resizedProfileImage = resizedProfileImage
    }

    // Codable
    enum CodingKeys: String, CodingKey {
        case _id
        case name
        case resizedProfileImage
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        name = try container.decode(String.self, forKey: .name)
        resizedProfileImage = try container.decodeIfPresent(String.self, forKey: .resizedProfileImage)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: ._id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(resizedProfileImage, forKey: .resizedProfileImage)
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
    let createdAt: String // MongoDB date string
    let updatedAt: String
}

struct MessageResponse: Codable {
    let message: String
    let messages: [VibeMessage]
}


/// Profile
struct ProfileResponse: Codable {
    let name: String?
    let email: String?
    let profileImageURL: String?
    let profileResizedImageURL: String?
}



// Buttons style -- placing it here for now
import SwiftUI
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

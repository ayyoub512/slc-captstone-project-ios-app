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
    let created_at: String // MongoDB date string
}

struct MessageResponse: Codable {
    let message: String
    let messages: [VibeMessage]
}

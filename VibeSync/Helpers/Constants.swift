//
//  Constants.swift
//  VibeSync
//
//  Created by Ayyoub on 14/2/2026.
//

import Foundation

enum NavigationPage {
    case inbox, camera, drawing, account
}

struct K {
    static let shared = K()
    let teamId = "DMADXVV944"
    let bundleIdentifier = "io.ayyoub.vibe-sync"
    
    // Key Chain
    var keyChainSharedAccessGroup: String {
        return "\(teamId).\(bundleIdentifier).shared"
    }
    let keyChainUserTokenKey = "userToken"
    let keychainAPNKey = "deviceAPNToken"
    let keychainInviteCodeKey = "inviteCode"
    let keychainUserIDKey = "userID"
    
    // API END POINTS
    let apiURL = "https://ef52-2001-1970-4c69-b400-cf3-2d8e-3024-bd3.ngrok-free.app/api"
    var logingURL: String { apiURL + "/auth/login" }
    var registerURL: String { apiURL + "/auth/register" }
    var registerDeviceURL: String { apiURL + "/register-device" }
    var sendNotificatioURL: String { apiURL + "/send-notification" }
    var friendsListURL: String { apiURL + "/getFriendList" }
    var getMessagesURL: String { apiURL + "/getMessagesByFriend" }
    var addFriendURL: String { apiURL + "/addFriend" }
    var getLatestMessageURL: String { apiURL + "/getNewestMessageByFriends" }

}

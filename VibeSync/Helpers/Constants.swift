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
    
        
    
    let appleEmail = "appleEmail"
    let applefullName = "applefullName"
    let appleUserId = "appleUserId"
    let appleIdentityToken = "appleIdentityToken"
    let appleUsername = "appleUsername"
    
    
    
    // API END POINTS
    let apiURL = "https://49a4-2001-1970-4c69-b400-884a-287c-addb-36d2.ngrok-free.app/api"
    var signInWithAppleURL: String { apiURL + "/auth/apple"}
    var logingURL: String { apiURL + "/auth/login" }
    var registerURL: String { apiURL + "/auth/register" }
    var registerDeviceURL: String { apiURL + "/register-device" }
    var sendNotificatioURL: String { apiURL + "/send-notification" }
    var friendsListURL: String { apiURL + "/getFriendList" }
    var getMessagesURL: String { apiURL + "/getMessagesByFriend" }
    var addFriendURL: String { apiURL + "/addFriend" }
    var getLatestMessageURL: String { apiURL + "/getNewestMessageByFriends" }

}

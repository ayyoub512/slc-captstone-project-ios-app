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

    // Apple
    let keychainApplefullName = "applefullName"
    let keychainAppleUserId = "appleUserId"

    // App Storage
    let appStorageLastFetchedFriends = "lastFetchedFriends"  // Time since last fetched friends - refresh every ~5 minutes
    let hasOnboarded = "hasOnboarded"
    let onboardingProfileName = "onboardingProfileName"
    let onBoardingProfileImageURL = "onBoardingProfileImageURL"
    let cachedUserName = "cachedUserName"
    let profileCachedImageFileName = "profile.jpg"

    // API END POINTS
//    let apiURL = "https://190a-2001-1970-4c69-b400-9d24-f1ef-4b29-6b60.ngrok-free.app/api"
    let apiURL = "https://vibesync.ayyoub.io/api"
    var signInWithAppleURL: String { apiURL + "/auth/apple" }
    var logingURL: String { apiURL + "/auth/login" }
    var registerURL: String { apiURL + "/auth/register" }
    var registerDeviceURL: String { apiURL + "/register-device" }
    var sendNotificatioURL: String { apiURL + "/send-notification" }
    var friendsListURL: String { apiURL + "/getFriendList" }
    var getMessagesURL: String { apiURL + "/getMessagesByFriend" }
    var addFriendURL: String { apiURL + "/addFriend" }
    var getLatestMessageURL: String { apiURL + "/getNewestMessageByFriends" }
    var updateProfileURL: String { apiURL + "/update-profile" }
    var deleteUserDataURL: String { apiURL + "/delete-user-data" }
    var getProfileURL: String { apiURL + "/get-profile" }
    var reportURL: String { apiURL + "/report" }
    var getFriendshipProfileURL: String { apiURL + "/friendship-profile" }
    var removeFriendURL: String { apiURL + "/remove-friend" }
    var markConversationReadURL: String{ apiURL + "/mark-conversation-read" }

    // Numbers
    var cachFriendsDurationSeconds: Double = 300

}

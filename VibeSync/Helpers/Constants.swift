//
//  Constants.swift
//  VibeSync
//
//  Created by Ayyoub on 14/2/2026.
//

import Foundation

struct K{
    static let shared = K()
    let teamId = "DMADXVV944"
    let bundleIdentifier = "io.ayyoub.vibe-sync"

    var keyChainSharedAccessGroup: String {
        return "\(teamId).\(bundleIdentifier).shared"
    }
    
    let keyChainUserTokenKey = "userToken"
    let keychainAPNKey = "deviceAPNToken"
    let apiURL = "https://08ef-72-38-32-73.ngrok-free.app/api" // "http://localhost:5001/api"
    
    var logingURL: String { apiURL + "/auth/login"}
    var registerURL: String { apiURL + "/auth/register" }
    var registerDeviceURL : String { apiURL + "/register-device" }
    var sendNotificatioURL : String { apiURL + "/send-notification" }
    
    
}

//
//  Constants.swift
//  VibeSync
//
//  Created by Ayyoub on 14/2/2026.
//

import Foundation

struct K{
    static let shared = K()
    let keyChainUserTokenKey = "userToken"
    let keychainAPNKey = "deviceAPNToken"
    let apiURL =   "https://5e10-2001-1970-4c69-b400-8d92-fa37-da-ad76.ngrok-free.app/api" // "http://localhost:5001/api"
    
    var logingURL: String { apiURL + "/auth/login"}
    var registerURL: String { apiURL + "/auth/register" }
    var registerDeviceURL : String { apiURL + "/register-device" }
    var sendNotificatioURL : String { apiURL + "/send-notification" }
    
    
}

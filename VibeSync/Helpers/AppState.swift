//
//  AppState.swift
//  VibeSync
//
//  Created by Ayyoub on 21/4/2026.
//

import Foundation

@Observable
class AppState {
    static let shared = AppState()
    private init() {}
    
    var needsFriendRefresh = false
    
    func triggerFriendRefresh() {
        Log.shared.debug(
            "[INFO: VibeSyncApp - VibeSyncDelegate] willPresent notification, old needsFriendRefresh=\(needsFriendRefresh)"
        )
        needsFriendRefresh = true
    }
}

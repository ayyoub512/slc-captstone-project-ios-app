//
//  NavigationManager.swift
//  VibeSync
//
//  Created by Ayyoub on 25/2/2026.
//

import Foundation
import SwiftUI

@Observable
class NavigationManager {
    static let shared = NavigationManager()
    private init() {}

    var selectedTab: Int = 1  // 0: Profile, 1: Camera, 2: Inbox
    var inboxPath = NavigationPath()
    var profilePath = NavigationPath()  // allows for progrmmation navigation

    var forceSwipeEnabled = false  // used from chat view

    // Only allow swipe between tabs at root
    var canSwipeTabs: Bool {
        if forceSwipeEnabled {
            return forceSwipeEnabled
        }
        
        return profilePath.isEmpty && inboxPath.isEmpty
    }

    func goToTab(id: Int) {
        withAnimation(.easeInOut) {
            selectedTab = id
        }
    }

    // Function to handle deep links (from Push Notifications)
    //    func openMessage(id: String) {
    //            // 1. Switch to Inbox tab
    //            selectedTab = 1
    //
    //            // 2. Clear any old screens and push the new message ID
    //            inboxPath = NavigationPath()
    //            inboxPath.append(id)
    //        }
}

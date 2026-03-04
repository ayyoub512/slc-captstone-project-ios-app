//
//  NavigationManager.swift
//  VibeSync
//
//  Created by Ayyoub on 25/2/2026.
//

import SwiftUI
import Foundation

@Observable
class NavigationManager {
    
    var selectedTab: Int = 1 // camera
    
    // Control the stack of the inbox
    var inboxPath = NavigationPath()
    
    var profilePath = NavigationPath() // allows for progrmmation navigation
    
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

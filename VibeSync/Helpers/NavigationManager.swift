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
    
    // 0 for camera/drawing, 1 = inbox
    var selectedTab: Int = 0
    
    // Control the stack of the inbox
    var inboxPath = NavigationPath()
    
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

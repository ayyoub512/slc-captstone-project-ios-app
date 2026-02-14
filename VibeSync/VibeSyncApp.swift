//
//  VibeSyncApp.swift
//  VibeSync
//
//  Created by Ayyoub on 11/2/2026.
//

import SwiftUI


@main
struct VibeSyncApp: App {
    @StateObject var authentication = AuthService()
    
    var body: some Scene {
        WindowGroup {
            if authentication.isAuthenticated{
                DrawingView()
                    .environmentObject(authentication)
            }else{
                LoginView()
                    .environmentObject(authentication)
                
            }
        }
    }
}

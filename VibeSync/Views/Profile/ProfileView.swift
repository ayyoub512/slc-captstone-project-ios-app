//
//  ProfileView.swift
//  VibeSync
//
//  Created by Ayyoub on 3/3/2026.
//

import SwiftUI

struct ProfileView: View {
    @Environment(NavigationManager.self) var navManager
    @EnvironmentObject var auth: AuthService
    @StateObject private var networkManager = NetworkManager()
    @State private var label: String = "Hi"
    @State private var isEditingText = false

    var body: some View {
        ZStack {
            VStack {
                AddFriendView()
                    .environmentObject(networkManager)
                    .environmentObject(auth)

            }

        }
        .onTapGesture {
            if isEditingText {
                print("Clicked away while isEditingText=true")
                isEditingText = false
            }
        }

        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    withAnimation {
                        navManager.selectedTab = 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.right")
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(.largeTitle.bold())
            }

        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService())
        .environment(NavigationManager())
}

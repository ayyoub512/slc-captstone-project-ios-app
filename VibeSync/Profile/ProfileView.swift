//
//  ProfileView.swift
//  VibeSync
//
//  Created by Ayyoub on 3/3/2026.
//

import SwiftUI

struct ProfileView: View {
    @Environment(NavigationManager.self) var navManager
    @State var auth = AuthService.shared
    @State private var label: String = "Hi"
    @State private var isEditingText = false

    var body: some View {

        Form {

            AddFriendView()

            Section(header: Text("Want to Sign Out").font(.headline)) {
                Button {
                    auth.logout()
                } label: {
                    HStack (alignment: .center) {
                        Image(systemName: "arrow.backward.square")
                        Text("Sign out")
                    }

                }
                .buttonStyle(.borderless)  // Makes it prominent
                .tint(Color.red.opacity(0.3))  // Slightly red
                .foregroundStyle(.red)

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
        .environment(NavigationManager())
}

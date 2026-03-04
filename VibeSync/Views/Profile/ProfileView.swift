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
                Image("image-example")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay {
                        VStack {
                            Spacer()
                            EditableLabel($label, isEditing: $isEditingText) {
                                print("Editing ended. New username: \(label)")
                            }
                            .font(.title2)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.black.opacity(0.6))
                            )
                            .fixedSize()
                        }
                        .padding()  // padding from the image edges
                    }

                Text("Current username: \(label)")

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

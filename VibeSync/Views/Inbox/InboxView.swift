//
//  InboxView.swift
//  VibeSync
//
//  Created by Ayyoub on 12/2/2026.
//

import SwiftUI

struct InboxView: View {
    @StateObject private var networkManager = NetworkManager()
    @EnvironmentObject var auth: AuthService
    @Environment(NavigationManager.self) var navManager
    @State private var showAddFriendSheet = false

    var body: some View {
        List {
            if networkManager.isLoading {
                ProgressView("Fetching your squad...")
            } else if let error = networkManager.errorMessage {
                Text(error).foregroundColor(.red)
            } else {
                ForEach(networkManager.friends) { friend in
                    NavigationLink(value: friend) {
                        FriendRow(friend: friend)
                    }
                }
            }
        }
        .navigationDestination(
            for: Friend.self,
            destination: { friend in
                ChatView(friend: friend)
            }
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    withAnimation {
                        navManager.selectedTab = 0
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Inbox")
                    .font(.largeTitle.bold())
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showAddFriendSheet = true }) {
                        Label("Add Friend", systemImage: "person.badge.plus")
                    }

                    Button(action: {
                        // Future: navigate to profile
                    }) {
                        Label("Profile", systemImage: "person.crop.circle")
                    }

                    Button(
                        role: .destructive,
                        action: {
                            // Logout logic
                            auth.logout()
                        }
                    ) {
                        Label("Logout", systemImage: "power")
                    }

                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                    //                            .foregroundStyle(.primary)
                }
            }
        }
        .task {
            if let token = auth.getToken() {
                await networkManager.fetchFriends(token: token)
            }
        }
        .sheet(isPresented: $showAddFriendSheet) {
            AddFriendView()
                .padding(.top, 10)
                .presentationDetents([.medium])
        }
    }
}

// A small sub-view to keep the code organized
struct FriendRow: View {
    let friend: Friend
    var body: some View {
        HStack {
            Text(friend.name.prefix(1).uppercased())
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.orange.gradient))

            VStack(alignment: .leading) {
                Text(friend.name)
                    .font(.headline)
                Text(friend.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        InboxView()
            .environmentObject(AuthService())  // Injecting the missing object
            .environment(NavigationManager())  // If you use NavManager too
    }
}

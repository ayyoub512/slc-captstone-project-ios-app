//
//  InboxView.swift
//  VibeSync
//
//  Created by Ayyoub on 12/2/2026.
//

import SwiftUI

struct InboxView: View {
    @StateObject private var viewModel = InboxViewModel()
    @EnvironmentObject var auth: AuthService
    @Environment(NavigationManager.self) var navManager

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView("Fetching your squad...")
            } else if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red)
            } else {
                ForEach(viewModel.friends) { friend in
                    NavigationLink(value: friend) {
                        FriendRow(friend: friend)
                    }
                }
            }
        }
        .navigationTitle("Inbox")
        .navigationDestination(for: Friend.self, destination: { friend in
            ChatView(friend: friend)
        })
        .toolbar {
            Button(action: { /* Logic to show Add Friend sheet */  }) {
                Image(systemName: "person.badge.plus")
            }
        }
        .task {
            if let token = auth.getToken() {
                await viewModel.fetchFriends(token: token)
            }
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

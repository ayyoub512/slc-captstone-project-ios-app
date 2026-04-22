//
//  InboxView.swift
//  VibeSync
//
//  Created by Ayyoub on 12/2/2026.
//

import SwiftData
import SwiftUI

struct InboxView: View {
    @State private var auth = AuthService.shared
    @State private var model = InboxViewModel()
    @State private var showAddFriendSheet = false

    @Environment(AppState.self) private var appState
    @Environment(NavigationManager.self) private var navManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FriendModel.lastMessageAt, order: .reverse) private
        var friends: [FriendModel]

    var body: some View {
        List {
            ForEach(friends, id: \._id) { friend in
                NavigationLink(value: friend) {
                    FriendRow(friend: friend)
                }
            }
        }
        .overlay {
            if friends.isEmpty {
                NoFriendsYetView()
            }
        }
        .refreshable {
            await model.fetchFriends(modelContext: self.modelContext)
        }
        .navigationDestination(
            for: FriendModel.self,
            destination: { friend in
                ChatView(friend: friend)
                    .environment(navManager)
                    .task {
                        // Mark as read when conversation opens
                        await model.markAsRead(friendID: friend._id)
                        friend.unreadCount = 0  // clear badge locally
                    }
            }
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    withAnimation {
                        navManager.selectedTab = 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Inbox")
                    .font(.title.bold())
                
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showAddFriendSheet = true }) {
                        Label("Add Friend", systemImage: "person.badge.plus")
                    }

                    Button(action: {
                        // Future: navigate to profile
                        navManager.goToTab(id: 0)
                    }) {
                        Label("Profile", systemImage: "person.crop.circle")
                    }

                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                }
            }
        }
        .task {
            Log.shared.debug(
                "[INFO: InboxView - onChange] needsRefresh: \(appState.needsFriendRefresh)"
            )
            await handleRefreshIfNeeded()
        }
        .onChange(of: appState.needsFriendRefresh) { _, needsRefresh in
            Log.shared.debug(
                "[INFO: InboxView - onChange] needsFriendRefresh: \(needsRefresh)"
            )
            guard needsRefresh else { return }
            appState.needsFriendRefresh = false  // reset immediately
            Task {
                await model.fetchFriends(modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showAddFriendSheet) {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack {
                    AddFriendView()
                        .padding()
                }
            }
            .presentationDetents([.medium])

        }
    }
    
    private func handleRefreshIfNeeded() async {
        if appState.needsFriendRefresh {
            appState.needsFriendRefresh = false
            await model.fetchFriends(modelContext: modelContext)
        } else if model.hasCacheExceededLimit() || friends.isEmpty {
            await model.fetchFriends(modelContext: modelContext)
        }
    }
}

// A small sub-view to keep the code organized
struct FriendRow: View {
    let friend: FriendModel
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                avatarView
                if friend.unreadCount > 0 {
                    Text(
                        friend.unreadCount > 99
                            ? "99+" : "\(friend.unreadCount)"
                    )
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.red))
                    .offset(x: 6, y: -4)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.headline)
                    .fontWeight(friend.unreadCount > 0 ? .bold : .regular)

                if let lastMessageDate = friend.lastMessageAt{
                    RelativeDateText(date: lastMessageDate)
                }else{
                    Text("No messages yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                

            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let imgURLString = friend.resizedProfileImage,
            let url = URL(string: imgURLString)
        {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                initialsView
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        Text(friend.name.prefix(1).uppercased())
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(Circle().fill(Color.orange))
    }
}

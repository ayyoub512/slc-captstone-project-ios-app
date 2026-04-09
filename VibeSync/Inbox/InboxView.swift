//
//  InboxView.swift
//  VibeSync
//
//  Created by Ayyoub on 12/2/2026.
//

import SwiftData
import SwiftUI

struct InboxView: View {
    @State var auth = AuthService.shared
    @StateObject private var model = InboxViewModel()
    @Environment(NavigationManager.self) var navManager
  
    @State private var showAddFriendSheet = false
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FriendModel.id) private var friends: [FriendModel]

    var body: some View {
        Group{
            if friends.count == 0 {
                NoFriendsYetView()
            }else{
                List {
                    
                    ForEach(friends, id: \._id) { friend in
                        NavigationLink(value: friend) {
                            FriendRow(friend: friend)
                        }
                    }
                }
                .navigationDestination(
                    for: FriendModel.self,
                    destination: { friend in
                        ChatView(friend: friend)
                            .environment(navManager)
                    }
                )
            }
        }
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
                if model.working {
                    ProgressView()
                } else {
                    Text("Inbox")
                        .font(.largeTitle.bold())
                }
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
                            auth.logout()
                        }
                    ) {
                        Label("Logout", systemImage: "power")
                    }

                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                }
            }
        }
        .task {
            if model.hasCacheExceededLimit() || friends.isEmpty {
                await model.fetchFriends(modelContext: self.modelContext)
            }
        }
        .sheet(isPresented: $showAddFriendSheet) {
            Form {
                AddFriendView()
                    .padding(.top, 10)
            }
            .presentationBackground(.brandPrimary)
            .presentationDetents([.medium])
        }
    }

}

// A small sub-view to keep the code organized
struct FriendRow: View {
    let friend: FriendModel
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
//    NavigationStack {
//        InboxView()
//            .environment(NavigationManager())  // If you use NavManager too
//            .modelContainer(for: [FriendModel.self])
//    }
}

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
            if model.hasCacheExceededLimit() || friends.isEmpty {
                Log.shared.debug("We have to refetch friends")
                await model.fetchFriends(modelContext: self.modelContext)
            } else {
                Log.shared.debug(
                    "[INFO: InboxView - InboxView] We dont have to refetch friends, friends: \(friends.count)"
                )
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

}

// A small sub-view to keep the code organized
struct FriendRow: View {
    let friend: FriendModel
    var body: some View {
        HStack {
            if let imgURL = friend.resizedProfileImage,
                let url = URL(string: imgURL)
            {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Text(friend.name.prefix(1).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.orange.gradient))
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                Text(friend.name.prefix(1).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.orange.gradient))
            }

            VStack(alignment: .leading) {
                Text(friend.name)
                    .font(.headline)
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

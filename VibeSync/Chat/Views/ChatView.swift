//
//  ConversationView.swift
//  VibeSync
//
//  Created by Ayyoub on 25/2/2026.
//

import SwiftUI

struct ChatView: View {
    let friend: FriendModel
    @State private var viewModel = ChatViewModel()
    @State private var showLargeImageViewSheet = false

    @Environment(NavigationManager.self) var navManager

    let myID: String = KeyChainManager.shared.get(
        key: K.shared.keychainUserIDKey
    )

    var body: some View {
        ZStack {
            if viewModel.messages.count > 0 {
                ScrollViewReader { proxy in
                    ScrollView {
                        if viewModel.messages.count
                            != viewModel.allMessagesCount
                        {
                            Button {
                                viewModel.appendNextPageMessages()
                            } label: {
                                Text("Load More")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 20)
                                    .padding(.horizontal, 10)
                                    .background(.brandPrimary)
                                    .clipShape(Capsule())
                            }
                        }

                        ForEach(viewModel.messages) { msg in
                            Group {
                                ChatBubbleView(
                                    message: msg,
                                    isFromMe: msg.senderID == myID
                                )
                                .id(msg.id)

                            }
                        }
                    }.onAppear {
                        guard viewModel.pageSize != viewModel.messages.count,
                            let last = viewModel.messages.last
                        else { return }
                        scrollToBottom(proxy: proxy, id: last.id)

                    }

                }
            }

            VStack(alignment: .trailing, spacing: 16) {
                Spacer()

                if viewModel.isLoading {
                    ProgressView("Getting messages...")
                }

                if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text(error)
                                .font(.callout)
                        }
                        .foregroundStyle(.red)

                        Button("Retry") {
                            Task { await loadContent() }
                        }
                        .buttonStyle(.glass)
                    }
                }

                Button {
                    navManager.goToTab(id: 1)
                    navManager.forceSwipeEnabled = true
                } label: {
                    Label("New Vibe", systemImage: "pencil")
                }
                .buttonStyle(.glass)

            }

        }
        .sheet(isPresented: $showLargeImageViewSheet) {
            LargeImageView()
                .presentationDetents([.large])
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(friend.name).font(.title.bold())
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    openFriendProfile()
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            
        }
        .task {
            await loadContent()
        }
        .navigationDestination(for: InboxRoute.self) { route in
            switch route {
            case .friendProfile(let id):
                FriendProfileView(for: id)
            }
        }
        
    }

    private func openFriendProfile() {
        navManager.inboxPath.append(InboxRoute.friendProfile(friend.id))
    }
    
    private func loadContent() async {
        await viewModel.fetchMessages(friendID: friend.id)
    }

    private func scrollToBottom(proxy: ScrollViewProxy, id: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }
}

#Preview {
    ChatView(
        friend: FriendModel(
            id: "69e40d70de036a0af6561124",
            name: "John Doe",
            resizedProfileImage:
                "https://scalar.usc.edu/works/norwegians-in-texas/media/TexasNorwegians_P0308_01.jpg"
        )
    )
    .environment(NavigationManager.shared)
}

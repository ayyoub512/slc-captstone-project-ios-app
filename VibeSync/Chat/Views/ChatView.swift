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
        ScrollViewReader { proxy in

            ScrollView {
                VStack(spacing: 15) {

                    if viewModel.messages.count
                        != viewModel.allMessagesCount
                    {
                        Button("Load more") {
                            viewModel.appendNextPageMessages()
                        }
                        .buttonStyle(.bordered)
                    }

                    ForEach(viewModel.messages) { msg in
                        ChatBubbleView(
                            message: msg,
                            isFromMe: msg.senderID == myID
                        )
                        .id(msg.id)
                    }
                }
                .padding(.vertical)
                .padding(.bottom, 80)
            }
            // ✅ Bug 1 fix: onChange moved here, outside the ScrollView content
            .onChange(of: viewModel.messages) {
                guard let last = viewModel.messages.last else { return }
                scrollToBottom(proxy: proxy, id: last.id)
            }
            .onChange(of: viewModel.lastLoadedMessageID) {
                guard let last = viewModel.messages.last else { return }
                scrollToBottom(proxy: proxy, id: last.id)
            }

        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 4) {
                if viewModel.isLoading {
                    ProgressView("Getting messages...")
                }

                if let error = viewModel.errorMessage {
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

                Button {
                    navManager.goToTab(id: 1)
                    navManager.forceSwipeEnabled = true  // since I disabled can swipe on chat view
                } label: {
                    Image(systemName: "pencil")
                    Text("New Vibe")
                        .padding(.vertical, 3)
                        .padding(.horizontal, 2)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.glass)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $showLargeImageViewSheet) {
            LargeImageView()
                .presentationDetents([.large])
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(friend.name).font(.largeTitle.bold())
            }
        }
        .task {
            await loadContent()
        }
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
            id: "69acec918787829a579f684a",
            name: "Ayyoub",
            email: "hi@ayyoub.io"
        )
    )
}

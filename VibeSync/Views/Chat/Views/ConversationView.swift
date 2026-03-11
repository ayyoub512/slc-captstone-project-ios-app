//
//  ConversationView.swift
//  VibeSync
//
//  Created by Ayyoub on 25/2/2026.
//

import SwiftUI

struct ConversationView: View {
    let friend: Friend
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var auth: AuthService

    // You need your own ID to align messages (Sent vs Received)
    let myID: String = KeyChainManager.shared.get(
        key: K.shared.keychainUserIDKey
    )  // TODO:  make it dynamic

    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack(spacing: 15) {
                        ForEach(viewModel.messages) { msg in
                            ChatBubbleView(
                                message: msg,
                                isFromMe: msg.senderID == myID
                            )
                            .id(msg.id)
                        }
                    }
                    .padding(.vertical)
                    .onChange(of: viewModel.messages) {
                        // Auto-scroll to most recent vibe
                        if let last = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            if viewModel.isLoading {
                ProgressView("Getting messages...")
            }
            
            if let error = viewModel.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text(error)
                    Button("Retry") {
                        Task{
                            await loadContent()
                        }
                    }
                    .buttonStyle(.glass)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial)
                )
            }

           

            
        }
        .navigationTitle(friend.name)
        .task {
            await loadContent()
        }
    }

    private func loadContent() async {

            print("Geeting all photos in this conversation")
            await viewModel.fetchMessages(friendID: friend.id)
        

    }
}

#Preview {
    //    MessageView()
}

//
//  MessageView.swift
//  VibeSync
//
//  Created by Ayyoub on 25/2/2026.
//

import SwiftUI

struct ChatView: View {
    let friend: Friend
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var auth: AuthService

    // You need your own ID to align messages (Sent vs Received)
    let myID: String = "699e1c0fce42532ffd4c2e51" // TODO:  make it dynamic

    var body: some View {
        ZStack {
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack(spacing: 15) {
                        ForEach(viewModel.messages) { msg in
                            VibeImageBubble(
                                url: msg.imageURL,
                                isFromMe: msg.senderID == myID
                            )
                            .id(msg.id)
                        }
                    }
                    .padding(.vertical)
                    .onChange(of: viewModel.messages) { _ in
                        // Auto-scroll to most recent vibe
                        if let last = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // 1. Loading Overlay
            if viewModel.isLoading {
                ProgressView("Getting messages...")
                    .background(Color.black.opacity(0.1))
            }

            // 2. Error Message Overlay
            if let error = viewModel.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text(error)
                    Button("Retry") {
                        Task { await loadContent() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial)
                )
            }
        }
        .navigationTitle(friend.name)
        .task { await loadContent() }
    }

    private func loadContent() async {
        if let token = auth.getToken() {
            await viewModel.fetchMessages(token: token, friendID: friend._id)
        }
    }
}

#Preview {
//    MessageView()
}

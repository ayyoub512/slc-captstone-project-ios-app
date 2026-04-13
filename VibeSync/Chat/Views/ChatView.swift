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
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 15) {

                            if viewModel.messages.count != viewModel.allMessagesCount {
                                HStack {
                                    Button("Load more") {
                                        viewModel.appendNextPageMessages()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }

                            ForEach(viewModel.messages) { msg in
                                ChatBubbleView(
                                    message: msg,
                                    isFromMe: msg.senderID == myID
                                )
                                .id(msg.id)
                                .onTapGesture {
                                    showLargeImageViewSheet.toggle()
                                }
                                
                            }
                        }
                        .padding(.vertical)
                        .onChange(of: viewModel.messages) {
                            
                            guard
                                let last = viewModel.messages.last,
                                viewModel.haLoadedFirstPage()
                            else { return }
                            DispatchQueue.main.async {
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
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.callout)
                            Text(error)
                                .font(.callout)
                                .foregroundStyle(.red)
                        }

                        Button("Retry") {
                            Task {
                                await loadContent()
                            }
                        }
                        .buttonStyle(.glass)
                    }
                }
            }

            VStack {
                Spacer()

                Button {

                } label: {
                    Image(systemName: "pencil")
                    Text("New Vibe")
                        .padding(.vertical, 3)
                        .padding(.horizontal, 2)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .zIndex(1)
                .buttonStyle(.glass)
                .padding()
            }
        }
        
        .sheet(isPresented: $showLargeImageViewSheet){
            LargeImageView()
                .presentationDetents([.large])
        }
        
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(friend.name)
                    .font(.largeTitle.bold())

            }
        }
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
    ChatView(
        friend: FriendModel(id: "69acec918787829a579f684a", name: "Ayyoub", email: "hi@ayyoub.io")
    )
}

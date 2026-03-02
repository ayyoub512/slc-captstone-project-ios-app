//
//  SendVibeSheetView.swift
//  VibeSync
//
//  Created by Ayyoub on 27/2/2026.
//

import SwiftUI
struct SendVibeSheetView: View {
    @ObservedObject var networkManager: NetworkManager
    @Binding var selectedFriendIDs: Set<String>
    @EnvironmentObject var auth: AuthService

    let capturedImage: UIImage

    var body: some View {
        VStack{
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                    if networkManager.isLoading {
                        ProgressView("Fetching pals...")
                    } else if let error = networkManager.errorMessage {
                        Text(error).foregroundColor(.red)
                    } else {
                        ForEach(networkManager.friends) { friend in
                            ContactBubble(
                                friend: friend,
                                isSelected: selectedFriendIDs.contains(friend.id)
                            ) {
                                toggle(friend.id)
                            }
                        }
                    }
                }
            }
            
            Button{
                Task {
                    let selectedIDs = Array(selectedFriendIDs) // Convert Set<String> → [String]
                    await networkManager.sendVibe(to: selectedIDs, with: auth.getToken() ?? "", image: capturedImage)
                }
            }label: {
                Text("Send")
            }.buttonStyle(.glassProminent)
        }
    }

    private func toggle(_ id: String) {
        if selectedFriendIDs.contains(id) {
            selectedFriendIDs.remove(id)
        } else {
            selectedFriendIDs.insert(id)
        }
    }
}

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
    @Binding var bakeImage: Bool
    @Binding var bakedImage: UIImage
//    let overlayText: String

    let capturedImage: UIImage

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    if let error = networkManager.errorMessage {
                        Text(error).foregroundColor(.red)
                    } else {
                        ForEach(networkManager.friends) { friend in
                            ContactBubble(
                                friend: friend,
                                isSelected: selectedFriendIDs.contains(
                                    friend.id
                                )
                            ) {
                                toggle(friend.id)
                            }
                        }
                    }
                }
                .padding(.top, 2)
            }

            Button {
                bakeImage = true
                print("Channging bakeImage to: true")
                Task {
                    let selectedIDs = Array(selectedFriendIDs)  // Convert Set<String> → [String]

                    await networkManager.sendVibe(
                        to: selectedIDs,
                        with: auth.getToken() ?? "",
                        image: bakedImage
                    )
                }
            } label: {
                if networkManager.working {
                    ProgressView()
                        .padding()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Send")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }.buttonStyle(.glassProminent)
                .disabled(networkManager.working)
        }
        .padding()
    }

    private func toggle(_ id: String) {
        if selectedFriendIDs.contains(id) {
            selectedFriendIDs.remove(id)
        } else {
            selectedFriendIDs.insert(id)
        }
    }

}

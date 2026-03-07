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
    @EnvironmentObject var viewModel: CameraViewModel
    var editorData: EditorData

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
                Task {
                    guard let size = editorData.viewSize else { return }
                    let rect = CGRect(
                        origin: .zero,
                        size: size
                    )

                    guard
                        let image = await editorData.exportAsImage(
                            rect,
                            scale: 2
                        )
                    else {
                        Log.shared.error(
                            "error: guard let image = await editorData.exportAsImage(rect, scale: 2 )"
                        )
                        return
                    }

                    await networkManager.sendVibe(
                        to: Array(selectedFriendIDs),  // Convert Set<String> → [String]
                        with: auth.getToken() ?? "",
                        image: image
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

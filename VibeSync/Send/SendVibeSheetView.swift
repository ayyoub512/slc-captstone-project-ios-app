//
//  SendVibeSheetView.swift
//  VibeSync
//
//  Created by Ayyoub on 27/2/2026.
//

import SwiftData
import SwiftUI

struct SendVibeSheetView: View {
    @StateObject var model = SendVibeSheetViewModel()
    @Binding var selectedFriendIDs: Set<String>
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FriendModel.id) private var friends: [FriendModel]

    var editorData: EditorData

    var body: some View {
        VStack {
            if friends.count == 0 {
                NoFriendsYetView()
                
            } else {
                Group{
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                            
                            if let error = model.errorMessage {
                                Text(error).foregroundColor(.red)
                            } else {
                                
                                ForEach(friends, id: \._id) { friend in
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
                            guard let size = editorData.viewSize else {
                                Log.shared.error("Error: guard return: guard let size = editorData.viewSize")
                                return
                            }
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
                            
                            await model.sendVibe(
                                to: Array(selectedFriendIDs),  // Convert Set<String> → [String]
                                image: image
                            )
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("send vibe")
                            
                            if model.working {
                                ProgressView()
                            } else if model.success != nil {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .fontWeight(.medium)
                        .font(.system(size: 18))
                        
                    }.buttonStyle(.glassProminent)
                        .disabled(model.working)
                }
                .padding()
            }
        }
        
        .task {
            if model.hasCacheExceededLimit() || friends.isEmpty {
                await model.fetchFriends(modelContext: self.modelContext)
            }
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

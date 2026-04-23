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
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FriendModel.id) private var friends: [FriendModel]

    var editorData: EditorData

    // Friends that were just sent to — captured right before clearing selection
    @State private var sentFriends: [FriendModel] = []
    @Environment(\.dismiss) private var dismiss

    @State private var showSuccessBanner = false
    @State private var isSent = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack {
                if friends.isEmpty {
                    NoFriendsYetView()
                } else {
                    // MARK: - Success overlay
                    if showSuccessBanner {
                        SuccessBannerView(
                            sentFriends: sentFriends,
                            count: sentFriends.count
                        )
                        .transition(.opacity)
                    } else if !isSent {
                        VStack {
                            ScrollView {
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 100))
                                ]) {
                                    if let error = model.errorMessage {
                                        Text(error).foregroundColor(.red)
                                    } else {
                                        ForEach(friends, id: \._id) { friend in
                                            ContactBubble(
                                                friend: friend,
                                                isSelected:
                                                    selectedFriendIDs.contains(
                                                        friend.id
                                                    )
                                            ) { toggle(friend.id) }
                                        }
                                    }
                                }
                                .padding(.top, 2)
                            }
                            
                            Button {
                                Task {
                                    guard let size = editorData.viewSize else {
                                        return
                                    }
                                    guard
                                        let image = await editorData.exportAsImage(
                                            CGRect(origin: .zero, size: size),
                                            scale: 2
                                        )
                                    else { return }
                                    
                                    // Capture before clearing
                                    sentFriends = friends.filter {
                                        selectedFriendIDs.contains($0.id)
                                    }
                                    
                                    await model.sendVibe(
                                        to: Array(selectedFriendIDs),
                                        image: image
                                    )
                                    
                                    if model.success != nil {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isSent = true
                                            showSuccessBanner = true
                                        }
                                        try? await Task.sleep(for: .seconds(2.2))
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showSuccessBanner = false
                                        }
                                        try? await Task.sleep(
                                            for: .milliseconds(200)
                                        )
                                        selectedFriendIDs.removeAll()
                                        dismiss()
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(model.working ? "sending..." : "send vibe")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundStyle(
                                            selectedFriendIDs.isEmpty
                                                ? Color(.tertiaryLabel)
                                                : Color(hex: "#EEEDFE")
                                        )

                                    Spacer()

                                    ZStack {
                                        Circle()
                                            .fill(
                                                selectedFriendIDs.isEmpty
                                                    ? Color(.quaternarySystemFill)
                                                    : Color.white.opacity(0.15)
                                            )
                                            .frame(width: 32, height: 32)

                                        if model.working {
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                                .tint(Color(hex: "#EEEDFE"))
                                                .scaleEffect(0.7)
                                        } else {
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(
                                                    selectedFriendIDs.isEmpty
                                                        ? Color(.tertiaryLabel)
                                                        : Color(hex: "#EEEDFE")
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            selectedFriendIDs.isEmpty
                                                ? Color(.secondarySystemBackground)
                                                : Color(hex: "#534AB7")
                                        )
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(model.working || selectedFriendIDs.isEmpty)
                        }
                        .padding()
                    }
                }
            }

        }
        .task {
            if appState.needsFriendRefresh {
                appState.needsFriendRefresh = false
                await model.fetchFriends(modelContext: modelContext)
            } else if model.hasCacheExceededLimit() || friends.isEmpty {
                await model.fetchFriends(modelContext: modelContext)
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

// MARK: - Success Banner
private struct SuccessBannerView: View {
    let sentFriends: [FriendModel]
    let count: Int

    var body: some View {
        VStack(spacing: 14) {
            // Stacked avatars of sent-to friends
            HStack(spacing: -10) {
                ForEach(sentFriends.prefix(4), id: \._id) { friend in
                    Group {
                        if let imgURLString = friend.resizedProfileImage,
                            let url = URL(string: imgURLString)
                        {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                initialsCircle(friend: friend, size: 30)
                            }
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                        } else {
                            initialsCircle(friend: friend, size: 30)
                        }
                    }
                    .overlay(
                        Circle().stroke(Color(.systemBackground), lineWidth: 2)
                    )

                }
            }

            // Checkmark
            ZStack {
                Circle()
                    .fill(Color.accent.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.accent)
            }

            VStack(spacing: 4) {
                Text("vibe sent")
                    .font(.system(size: 16, weight: .medium))
                Text("delivered to \(count) friend\(count == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .background(Color(.systemBackground))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        

    }

    private func initialsCircle(friend: FriendModel, size: CGFloat) -> some View
    {
        Text(friend.name.prefix(1).uppercased())
            .font(.system(size: size * 0.4, weight: .medium))
            .foregroundStyle(Color.accent)
            .frame(width: size, height: size)
            .background(Color.accent.opacity(0.12), in: Circle())
    }
}

//
//  ChatUserProfile.swift
//  VibeSync
//
//  Created by Ayyoub on 19/4/2026.
//

import SwiftUI

struct FriendProfileView: View {
    @State private var model: FriendProfileViewModel
    @State private var reportManager = ReportManager()
    @State private var showSuccessAlert = false
    @State private var showRemoveFriendDialog = false
    @Environment(NavigationManager.self) private var navManager
    var friendId: String

    init(for friendId: String) {
        _model = State(initialValue: FriendProfileViewModel(for: friendId))
        self.friendId = friendId
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: - Header
                VStack(spacing: 6) {
                    ZStack(alignment: .bottomTrailing) {
                        if let displayProfileImageURL = model.profileImageURL {
                            AsyncImage(url: displayProfileImageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Circle().fill(Color(.systemGray5))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.secondary)
                                    )
                            }
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(
                                    Color(.systemBackground),
                                    lineWidth: 4
                                )
                            )
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(
                                        Color(.systemBackground),
                                        lineWidth: 4
                                    )
                                )
                        }

                    }

                    Text(model.name ?? "")
                        .font(.system(size: 22, weight: .bold))

                    Text(
                        "Added on \(model.friendSince?.formattedDateString ?? "")"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.top, 28)
                .padding(.bottom, 28)

                if case .error(let err) = model.state {
                    Text(err)
                        .foregroundColor(.red)
                        .padding()
                }

                // MARK: - Stats
                HStack(spacing: 12) {
                    StatCard(
                        icon: "message.fill",
                        iconColor: .brandPrimary,
                        label: "MESSAGES SHARED",
                        value: model.messageCount?.formatted() ?? "0"
                    )
                    StatCard(
                        icon: "calendar",
                        iconColor: .brandPrimary,
                        label: "FRIEND SINCE",
                        value: model.friendSince?.formattedDateString ?? "0"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.horizontal, 16)
                .padding(.bottom, 28)

                // MARK: - Account Actions
                VStack(alignment: .leading, spacing: 10) {
                    Text("ACCOUNT ACTIONS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    ActionRow(
                        icon: "flag.fill",
                        label: "Report User",
                        color: .primary,
                        action: {
                            Task {
                                await reportManager.reportUser(userId: friendId)
                            }
                        }
                    )

                    ActionRow(
                        icon: "person.badge.minus",
                        label: "Remove Friend",
                        color: .red,
                        action: {
                            showRemoveFriendDialog = true
                        }
                    )
                }
                .padding(.horizontal, 16)
            }
        }
        .confirmationDialog(
            "Delete Friend & Conversation",
            isPresented: $showRemoveFriendDialog,
            titleVisibility: .visible
        ) {

            Button("Permanently Delete", role: .destructive) {
                Task {
                    await model.removeFriend()
                    
                    await MainActor.run {
                        // Clear the path first so the stack pops cleanly
                        NavigationManager.shared.reset()
                        AppState.shared.needsFriendRefresh = true
                        NavigationManager.shared.goToTab(id: 2)
                    }
                }
            }

            Button("Cancel", role: .cancel) {}

        } message: {
            Text(
                """
                Removing this friend will permanently delete your entire chat history with them.

                All messages sent and received will be erased and cannot be recovered.
                """
            )
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onChange(of: reportManager.state) { _, state in
            if case .success = state {
                showSuccessAlert = true
            }
        }
        .overlay {
            if case .loading = model.state {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("please wait...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .overlay {
            if case .loading = reportManager.state {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("please wait...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .alert("Report submitted", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Report submitted. Our team will review it.")
        }

    }
}



#Preview {
    FriendProfileView(for: "69e40d70de036a0af6561124")
}

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
                
                if case .success = model.state {
                    Text("Friend and conversation deleted")
                        .foregroundColor(.green)
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
                        icon: "nosign",
                        label: "Block User",
                        color: .red,
                        action: {}
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
                }
            }

            Button("Cancel", role: .cancel) { }
            
        } message: {
            Text("""
            Removing this friend will permanently delete your entire chat history with them.

            All messages sent and received will be erased and cannot be recovered.
            """)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onChange(of: reportManager.state) { _, state in
            if case .success = state {
                showSuccessAlert = true
            }
        }
        .alert("Report submitted", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Report submitted. Our team will review it.")
        }

    }
}

// MARK: - Subviews

private struct StatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(iconColor)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .font(
                    .system(
                        size: label == "FRIEND SINCE" ? 18 : 26,
                        weight: .bold
                    )
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct ActionRow: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        color == .primary
                            ? Color(.tertiaryLabel) : color.opacity(0.6)
                    )
            }
            .foregroundStyle(color == .primary ? Color.primary : color)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FriendProfileView(for: "69e40d70de036a0af6561124")
}

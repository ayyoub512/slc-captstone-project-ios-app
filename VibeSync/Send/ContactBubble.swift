//
//  ContactBubble.swift
//  VibeSync
//
//  Created by Ayyoub on 27/2/2026.
//

import SwiftUI

struct ContactBubble: View {
    let friend: FriendModel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                avatarView
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.accent : .clear, lineWidth: 2)
                    )
                    .animation(.spring(response: 0.2), value: isSelected)

                if isSelected {
                    ZStack {
                        Circle()
                            .fill(Color.accent)
                            .frame(width: 18, height: 18)
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 56, height: 56)

            Text(friend.name)
                .font(.system(size: 12))
                .foregroundStyle(isSelected ? Color.accent : .secondary)
                .fontWeight(isSelected ? .medium : .regular)
                .lineLimit(1)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.spring(response: 0.2)) { onTap() } }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let imgURLString = friend.resizedProfileImage,
           let url = URL(string: imgURLString) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                initialsView
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        Text(friend.name.prefix(1).uppercased())
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(Color.accent)
            .frame(width: 56, height: 56)
            .background(Color.accent.opacity(0.12), in: Circle())
    }
}

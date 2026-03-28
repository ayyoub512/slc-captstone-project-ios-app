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
                Text(friend.name.prefix(1).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle().fill(isSelected ? Color.blue : Color.blue.opacity(0.3))
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.white : .clear, lineWidth: 3)
                    )

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.blue))
                        .offset(x: 4, y: 4)
                }
            }

            Text(friend.name)
                .font(.subheadline)
                .foregroundColor(isSelected ? .blue : .primary)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

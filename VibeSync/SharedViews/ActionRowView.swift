//
//  ActionRowView.swift
//  VibeSync
//
//  Created by Ayyoub on 22/4/2026.
//

import SwiftUI

struct ActionRow: View {
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


struct StatCard: View {
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
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

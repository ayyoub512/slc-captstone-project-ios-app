//
//  CameraHeaderView.swift
//  VibeSync
//
//  Created by Ayyoub on 27/2/2026.
//

import SwiftUI
struct CameraHeaderView: View {
    var body: some View {
        HStack {
            Spacer()
            Text("Vibe Sync")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.vertical)
    }
}


private var swipeIndicator: some View {
    HStack {
        // Left swipe hint → Profile
        HStack(spacing: 4) {
            Image(systemName: "chevron.left")
                .font(.caption)
            Image(systemName: "person.fill")
                .font(.caption)
        }
        .foregroundStyle(.gray.opacity(0.6))

        Spacer()
        Text("Vibz")
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(.white)
        Spacer()

        // Right swipe hint → Inbox
        HStack(spacing: 4) {
            Image(systemName: "tray.fill")
                .font(.caption)
            Image(systemName: "chevron.right")
                .font(.caption)
        }
        .foregroundStyle(.gray.opacity(0.6))
    }
    .padding(.horizontal)
}

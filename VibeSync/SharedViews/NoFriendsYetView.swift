//
//  NoFriendsYetView.swift
//  VibeSync
//
//  Created by Ayyoub on 9/4/2026.
//

import SwiftUI

struct NoFriendsYetView: View {
    @State private var showAddFriendSheet = false

    var body: some View {
        VStack(spacing: 18) {

            Image(systemName: "person.3.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.top, 20)

            Text("No friends yet")
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)

            Text(
                "Add friends to start sharing photos and moments instantly."
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

            Button {
                showAddFriendSheet = true
            } label: {
                Text("Add a Friend")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.brandPrimary)
                    )
                    .shadow(
                        color: Color.brandPrimary.opacity(0.25),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 40)

        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)

        .sheet(isPresented: $showAddFriendSheet) {
            Form {
                AddFriendView()
                    .padding(.top, 10)
            }
            .presentationBackground(.brandPrimary)
            .presentationDetents([.medium])
        }
    }
}


#Preview {
    NoFriendsYetView()
}

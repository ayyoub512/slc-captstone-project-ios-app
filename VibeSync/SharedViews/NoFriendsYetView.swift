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
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                // Icon or illustration
                Image(systemName: "person.3.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Message
                Text("You have no friends yet!")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 40)

                Text("Add friends to start sharing moments.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Add Friend Button  @uw5vByJT^Xk1nytsKqk
                Button (action: { showAddFriendSheet = true }) { 
                    Text("Add a Friend")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                        .shadow(
                            color: Color.purple.opacity(0.3),
                            radius: 5,
                            x: 0,
                            y: 5
                        )
                }
                .padding(.horizontal, 50)
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
        .frame(minWidth: 300, maxWidth: 600, minHeight: 300)  // Medium-size sheet friendly
        .sheet(isPresented: $showAddFriendSheet) {
            Form {
                AddFriendView()
                    .padding(.top, 10)
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    NoFriendsYetView()
}

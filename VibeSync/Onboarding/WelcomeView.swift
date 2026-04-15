//
//  WelcomeView.swift
//  VibeSync
//
//  Created by Ayyoub on 15/4/2026.
//

import SwiftUI

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {

            Spacer()

            // App Icon
            Image("AppIcon") // replace with your asset name
                .resizable()
                .frame(width: 100, height: 100)
                .cornerRadius(22)

            // Title
            Text("Vibe Sync")
                .font(.system(size: 34, weight: .bold))

            // Subtitle (2 lines)
            Text("Live pics from your friends, on your home screen")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)

            Spacer()

            // Button
            Button(action: {
                print("Get Started tapped")
            }) {
                Text("Get Started")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
            }

            Spacer()
                .frame(height: 20)
        }
    }
}
#Preview {
    WelcomeView()
}

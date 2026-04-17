//
//  OnboardingNameView.swift
//  VibeSync
//
//  Created by Ayyoub on 16/4/2026.
//

import SwiftUI

struct ProfileNameSetupView: View {
    @AppStorage(K.shared.onboardingProfileName) var userName: String = ""

    @State private var name: String = ""
    @FocusState private var isFocused: Bool

    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {

            Spacer()
                .frame(height: 20)

            // Title
            VStack(spacing: 12) {
                Text("What’s your name?")
                    .font(.system(size: 28, weight: .semibold))

                Text("This helps your friends recognize you.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Input
            TextField("name", text: $name)
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)

            Spacer()

            // Button
            Button {
                userName = name.trimmingCharacters(in: .whitespaces)
                onContinue()
            } label: {
                HStack(spacing: 8) {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    name.isEmpty ? Color.gray.opacity(0.4) : Color.blue
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 24)

            Spacer()
                .frame(height: 20)
        }
        .background(Color(.systemBackground))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = false
        }
    }
}

#Preview {
    ProfileNameSetupView {

    }
}

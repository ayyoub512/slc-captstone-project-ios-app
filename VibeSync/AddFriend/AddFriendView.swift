//
//  AddFriendView.swift
//  VibeSync
//
//  Created by Ayyoub on 2/3/2026.
//

import SwiftUI
import UIKit

struct AddFriendView: View {
    @State private var code: String = ""
    @StateObject var model = AddFriendViewModel()

    @FocusState private var isCodeFocused: Bool

    var body: some View {

        VStack(spacing: 30) {

            // MARK: - Add Friend Card
            VStack(alignment: .leading, spacing: 14) {

                Text("Enter friend’s invite code")
                    .font(.headline)

                TextField("Enter invite code", text: $code)
                    .focused($isCodeFocused)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    submitCode()
                } label: {
                    HStack {
                        Spacer()

                        if model.working {
                            ProgressView()
                        } else {
                            Text("Add friend")
                        }

                        Spacer()
                    }
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

                if model.success == true {
                    Label(
                        "Added successfully",
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.green)
                }

                if let error = model.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            // MARK: - Share Invite Code Card
            VStack(alignment: .leading, spacing: 14) {

                Text("Share your invite code")
                    .font(.headline)


                HStack {
                    Text("Your invite code")
                        .foregroundStyle(.foreground)
                    Spacer()

                    let invite = KeyChainManager.shared.get(
                        key: K.shared.keychainInviteCodeKey
                    )
                    CopyableText(text: invite)
                }

                Text("Send this code to a friend to add you")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

            }

        }
        .contentShape(Rectangle())
        .onTapGesture {
            isCodeFocused = false
        }

    }

    private func submitCode() {
        Task {
            await model.addFriend(with: code)
            if model.success ?? false {
                await MainActor.run {
                    // Clear the path so the stack pops cleanly
                    NavigationManager.shared.reset()
                    AppState.shared.needsFriendRefresh = true
                    NavigationManager.shared.goToTab(id: 2)
                }
            }

        }
    }
}

struct CopyableText: View {
    let text: String

    @State private var didCopy = false

    var body: some View {
        HStack(spacing: 12) {
            Text(text)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .tracking(2)
                .foregroundStyle(.primary)
                .textSelection(.enabled)

            Image(systemName: didCopy ? "checkmark.circle.fill" : "doc.on.doc")
                .font(.body)
                .foregroundStyle(didCopy ? .accent : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .opacity(0.1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14))  // makes full area tappable
        .onTapGesture {
            copyToClipboard()
        }
        .animation(.easeInOut(duration: 0.2), value: didCopy)
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = text

        didCopy = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            didCopy = false
        }
    }
}

#Preview {

    Form {
        AddFriendView()
    }
}

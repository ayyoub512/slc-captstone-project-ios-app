//
//  ProfileView.swift
//  VibeSync
//
//  Created by Ayyoub on 3/3/2026.
//

import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext  // the main reason for this is to clear the cached friends list on logout
    @Environment(NavigationManager.self) var navManager
    @State var auth = AuthService.shared
    private let kcManager = KeyChainManager.shared

    @State private var showEditName = false
    @State private var editedName = ""

    @State private var viewModel = ProfileViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: - Profile Header
                VStack(spacing: 14) {

                    Text(
                        kcManager.get(key: K.shared.keychainApplefullName)
                            .prefix(1)
                            .uppercased()
                    )
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 96, height: 96)
                    .background(
                        Circle()
                            .fill(Color.brandPrimary.gradient)
                    )

                    Text(kcManager.get(key: K.shared.keychainApplefullName))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)

                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
                .onTapGesture {
                    // edit name
                }

                // MARK: - Add Friend

                VStack {
                    AddFriendView()
                        .padding()
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                

                
                // MARK: - Sign Out
                Button {
                    auth.logout(modelContext: modelContext)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.backward.square")
                        Text("Sign out")
                        Spacer()
                    }
                    .foregroundStyle(.red)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                

                // MARK: - Delete Account
                VStack(alignment: .leading, spacing: 10) {

                    Button(role: .destructive) {
                        viewModel.showDeleteConfirmation = true
                    } label: {
                        HStack(spacing: 12) {
                            if viewModel.isDeleting {
                                ProgressView()
                                    .tint(.red)
                            } else {
                                Image(
                                    systemName: "person.crop.circle.badge.minus"
                                )
                            }

                            Text("Delete Account")
                            Spacer()
                        }
                        .foregroundStyle(.red)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(viewModel.isDeleting)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 4)
                    }

                    Text(
                        "This permanently deletes your account, all messages, and images. This cannot be undone."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                }

            }
            .padding(.horizontal, 12)


        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())

        .sheet(isPresented: $showEditName) {
            EditNameSheet(
                name: $editedName,
                onSave: {
                    handleNameChange(editedName)
                    showEditName = false
                }
            )
            .presentationDetents([.medium])
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    withAnimation {
                        navManager.goToTab(id: 1)
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.right")
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(.largeTitle.bold())
            }

        }
        .confirmationDialog(
            "Delete Account",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete My Account", role: .destructive) {
                Task {
                    let success = await viewModel.deleteAccount()
                    if success {
                        auth.logout(modelContext: modelContext)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Are you sure? This will permanently delete all your data and cannot be undone."
            )
        }
    }
}

struct EditNameSheet: View {
    @Binding var name: String
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Enter name", text: $name)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 0)
            }
            .navigationTitle("Edit Name")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Change") {
                        onSave()
                    }
                    .buttonStyle(.glassProminent)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onSave()  // or dismiss separately if you prefer
                    }

                }
            }
        }
    }
}

func handleNameChange(_ newName: String) {
    print("Name changed to:", newName)
}

#Preview {
    ProfileView()
        .environment(NavigationManager.shared)
}

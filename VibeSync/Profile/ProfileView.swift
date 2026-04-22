//
//  ProfileView.swift
//  VibeSync
//
//  Created by Ayyoub on 3/3/2026.
//

import PhotosUI
import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationManager.self) var navManager
    @State var auth = AuthService.shared
    private let kcManager = KeyChainManager.shared

    @State private var showEditName: Bool = false
    @State private var editedName = ""

    @State private var viewModel = ProfileViewModel()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: - Profile Header
                VStack(spacing: 14) {
                    ZStack {
                        if let image = viewModel.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                )
                                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 110, height: 110)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.gray)
                        }

                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.black.opacity(0.6))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "pencil")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(width: 110, height: 110)
                    }

                    Button {
                        editedName = viewModel.name ?? ""
                        showEditName = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(viewModel.name ?? "Set your name")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(viewModel.name == nil ? .secondary : .primary)

                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // MARK: - Sync State Banner
                syncBannerView

                // MARK: - Add Friend
                VStack {
                    AddFriendView()
                        .padding()
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                signoutBtn

                deleteAccountBtn
            }
            .padding(.horizontal, 12)
            .animation(.easeInOut(duration: 0.2), value: viewModel.syncState)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                {
                    viewModel.updateImage(image)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    withAnimation { navManager.goToTab(id: 1) }
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(.largeTitle.bold())
            }
        }
        .onAppear {
            viewModel.loadCachedProfile()
            if viewModel.name == nil {
                Task { await viewModel.fetchProfileFromServer() }
            }
        }
        .alert("Edit Name", isPresented: $showEditName) {
            TextField("Your name", text: $editedName)
                .autocorrectionDisabled()
            Button("Save") {
                guard !editedName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                viewModel.updateName(editedName.trimmingCharacters(in: .whitespaces))
            }
            Button("Cancel", role: .cancel) {}
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
                        UserDefaults.standard.set(false, forKey: K.shared.hasOnboarded)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure? This will permanently delete all your data and cannot be undone.")
        }
    }

    // MARK: - Sync Banner
    // Replace syncBannerView
    @ViewBuilder
    private var syncBannerView: some View {
        switch viewModel.syncState {
        case .idle:
            EmptyView()
        case .loading:
            syncBanner(icon: nil, message: "Saving changes...", color: AnyShapeStyle(.secondary), showSpinner: true)
        case .success:
            syncBanner(icon: "checkmark.circle.fill", message: "Saved", color: AnyShapeStyle(Color.green), showSpinner: false)
        case .error(let message):
            syncBanner(icon: "exclamationmark.circle.fill", message: message, color: AnyShapeStyle(Color.red), showSpinner: false)
        }
    }

    // Replace syncBanner func signature and body
    @ViewBuilder
    private func syncBanner(icon: String?, message: String, color: AnyShapeStyle, showSpinner: Bool) -> some View {
        HStack(spacing: 8) {
            if showSpinner {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let icon {
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            Text(message)
                .font(.footnote)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Buttons

    var deleteAccountBtn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(role: .destructive) {
                viewModel.showDeleteConfirmation = true
            } label: {
                HStack(spacing: 12) {
                    if viewModel.isDeleting {
                        ProgressView().tint(.red)
                    } else {
                        Image(systemName: "person.crop.circle.badge.minus")
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

            Text("This permanently deletes your account, all messages, and images. This cannot be undone.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    var signoutBtn: some View {
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
    }
}

#Preview {
    ProfileView()
        .environment(NavigationManager.shared)
}

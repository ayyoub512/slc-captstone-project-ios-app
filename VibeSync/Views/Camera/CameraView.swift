import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @StateObject private var networkManager = NetworkManager()
    @EnvironmentObject var auth: AuthService

    @State private var showSendMessageSheet = false
    @State private var selectedFriendIDs: Set<String> = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                CameraHeaderView()
                    .padding(.top, 50)

                Spacer()

                CameraPreviewContainer(viewModel: viewModel)

                Spacer()

                CameraBottomControlsView(
                    viewModel: viewModel,
                    onSendTapped: {
                        showSendMessageSheet = true
                    }
                )
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            viewModel.checkPermissions()
        }
        .onChange(of: viewModel.capturedImage) { old, new in
            if new != nil, old == nil {
                loadFriendsIfNeeded()
            }
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .alert(
            "Camera Access Required",
            isPresented: $viewModel.showPermissionAlert
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Settings") {
                if let settingsUrl = URL(
                    string: UIApplication.openSettingsURLString
                ) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        } message: {
            Text("Please enable camera access in Settings to capture vibes.")
        }
        .sheet(isPresented: $showSendMessageSheet) {
            if let image = viewModel.capturedImage {
                SendVibeSheetView(
                    networkManager: networkManager,
                    selectedFriendIDs: $selectedFriendIDs,
                    capturedImage: image
                )
                .environmentObject(auth)
                .presentationDetents([.medium])
            } else {
                Text("No image available")
            }

        }
    }

    private func loadFriendsIfNeeded() {
        guard let token = auth.getToken() else { return }
        Task {
            await networkManager.fetchFriends(token: token, forceRefresh: false)
        }
    }
}

// MARK: - Preview
#Preview {
    CameraView()
}

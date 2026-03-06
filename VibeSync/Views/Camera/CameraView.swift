import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @StateObject private var networkManager = NetworkManager()
    @EnvironmentObject var auth: AuthService
    
    @EnvironmentObject var notificationManager: NotificationsManager
    @State private var showNotificationPrompt = false
    
    @State private var showSendMessageSheet = false
    @State private var selectedFriendIDs: Set<String> = []
    
    @State private var isEditingText = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                CameraHeaderView()

//                CameraPreviewContainer(viewModel: viewModel)
                
                CameraPreviewContainer(viewModel: viewModel, isEditingText: $isEditingText)

                Spacer()

                CameraBottomControlsView(
                    viewModel: viewModel,
                    onSendTapped: {
                        showSendMessageSheet = true
                    }
                )
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
            if viewModel.capturedImage != nil {
                SendVibeSheetView(
                    networkManager: networkManager,
                    selectedFriendIDs: $selectedFriendIDs,
                )
                .environmentObject(auth)
                .environmentObject(viewModel)
                .presentationDetents([.medium])
            } else {
                Text("No image available")
            }

        }
        // Notification
        .task {
            await notificationManager.getAuthStatus()
            if auth.isAuthenticated {
                if !notificationManager.hasPermission {
                    showNotificationPrompt = true
                }
            }
        }
        .sheet(isPresented: $showNotificationPrompt) {
            NotificationPromptView()
                .environmentObject(notificationManager)
        }
        .onTapGesture {
            if isEditingText {
                print("Clicked away while isEditingText=true")
                isEditingText = false
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

import PhotosUI
import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @StateObject private var networkManager = NetworkManager()
    @EnvironmentObject var auth: AuthService

    @EnvironmentObject var notificationManager: NotificationsManager
    @State private var showNotificationPrompt = false

    @State private var showSendMessageSheet = false
    @State private var selectedFriendIDs: Set<String> = []

    @State private var editorData = EditorData()
  
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                CameraHeaderView()

                Spacer()
                ZStack{
                    GeometryReader { geo in
                        ZStack{
                            if let image = viewModel.capturedImage {
                                EditorView(size: geo.size, data: editorData, image: image)
                            } else {
                                CameraPreviewView(session: viewModel.session)
                            }
                            
                            
                        }
                    }
                    
                    if viewModel.capturedImage == nil {
                        VStack {
                            HStack {
                                Spacer()
                                flipCameraButton
                                    .padding(16)
                            }
                            Spacer()
                        }
                    }
                }

                Spacer()

                CameraBottomControlsView(
                    viewModel: viewModel,
                    editorData: editorData,
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
                    editorData: editorData
                )
                .environmentObject(auth)
//                .environmentObject(viewModel)
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

    }

    private func loadFriendsIfNeeded() {
        guard let token = auth.getToken() else { return }
        Task {
            await networkManager.fetchFriends(token: token, forceRefresh: false)
        }
    }
    
    private var flipCameraButton: some View {
        Button {
            viewModel.flipCamera()
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                .foregroundColor(.white)
                .padding(12)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
        .padding(16)
    }
}

// MARK: - Preview
#Preview {
    CameraView()
}

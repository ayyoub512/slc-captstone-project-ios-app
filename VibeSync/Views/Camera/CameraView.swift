import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @StateObject private var networkManager = NetworkManager()
    @EnvironmentObject var auth: AuthService
    @State private var showSendMessageSheet = false

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 50)

                Spacer()

                // Camera Rectangle Container
                cameraRectangleView

                Spacer()

                // Bottom Controls
                bottomControlsView
                    .padding(.bottom, 40)
            }
        }
        // Lazy loading: Fetch when photo is captured
        .onChange(of: viewModel.capturedImage) { oldValue, newValue in
            if newValue != nil, oldValue == nil {
                // Photo just captured - pre-fetch friends
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
            Text("Please enable camera access in Settings to send vibes.")
        }
        .sheet(
            isPresented: $showSendMessageSheet,
        ) {
            sendMessageSheetView
                .presentationDetents([.medium])
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Spacer()

            Text("Vibz")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)

            Spacer()
        }
    }

    // MARK: - Camera Rectangle
    private var cameraRectangleView: some View {
        ZStack {
            // Camera/Image Container
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    Group {
                        if let capturedImage = viewModel.capturedImage {
                            // Show captured image
                            Image(uiImage: capturedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            // Show live camera feed
                            CameraPreviewView(session: viewModel.session)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))

            // Flip Camera Button (only visible during live feed)
            if viewModel.capturedImage == nil {
                VStack {
                    HStack {
                        Spacer()

                        Button {
                            viewModel.flipCamera()
                        } label: {
                            Image(
                                systemName:
                                    "arrow.triangle.2.circlepath.camera.fill"
                            )
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                        }
                        .padding(16)
                    }

                    Spacer()
                }
            }
        }
        .frame(height: 520)
    }

    // MARK: - Bottom Controls
    private var bottomControlsView: some View {
        HStack(spacing: 24) {
            if viewModel.capturedImage != nil {
                // Retake and Send buttons (after capture)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.retakePhoto()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Retake")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                }

                Button {
                    // viewModel.sendVibe()
                    showSendMessageSheet = true

                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Send")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(12)
                }
            } else {
                // Upload and Capture buttons (during live feed)
                Button {
                    // TODO: Implement upload from gallery
                    print("Upload tapped")

                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                        Text("upload")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                }

                // Capture Button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.capturePhoto()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.cyan, lineWidth: 5)
                            .frame(width: 80, height: 80)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 68, height: 68)
                    }
                }

                Button {
                    // TODO: Implement edit/pen functionality
                    print("Edit tapped")
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
    }
    //  Smart loading function
    private func loadFriendsIfNeeded() {
        guard let token = auth.getToken() else { return }
        
        Task {
            await networkManager.fetchFriends(token: token, forceRefresh: false)
        }
    }

    
    // MARK: - Send message sheet
    var sendMessageSheetView: some View {
        
        ScrollView {  // Wrap in ScrollView
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {  // Lazy loading
                if networkManager.isLoading {
                    ProgressView("Fetching pals...")
                    
                } else if let error = networkManager.errorMessage {
                    Text(error).foregroundColor(.red)
                } else {
                    ForEach(networkManager.friends) { friend in
                        ContactBuble(friend: friend)
                    }
                }
            }
        }

    }

}

// A small sub-view to keep the code organized
struct ContactBuble: View {
    let friend: Friend
    var body: some View {
        VStack {
            Text(friend.name.prefix(1).uppercased())
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.orange.gradient))

            Text(friend.name)
                .font(.headline)
        }
       
    }
}

// MARK: - Preview
#Preview {
    CameraView()
}

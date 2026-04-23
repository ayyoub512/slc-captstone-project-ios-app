import PhotosUI
import SwiftData
import SwiftUI

struct CameraView: View {
    @EnvironmentObject var notificationManager: APNSNotificationsManager
    @StateObject private var viewModel = CameraViewModel()
    @Environment(NavigationManager.self) private var navManager

    @State private var showNotificationPermissionPrompt = false
    @State private var showSendMessageSheet = false
    @State private var selectedFriendIDs: Set<String> = []
    @State private var editorData = EditorData()
    @State private var useCameraMode: Bool = true  // [Camera Mode Or Canvas Mode] - By default uses Camera mode

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color(
                .black
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                ZStack {
                    GeometryReader { geo in
                        ZStack {
                            if useCameraMode {
                                if let image = viewModel.capturedImage {
                                    EditorView(
                                        size: geo.size,
                                        data: editorData,
                                        image: image
                                    )
                                    .id(editorData.resetID)
                                } else {
                                    CameraPreviewView(
                                        session: viewModel.session
                                    )
                                    .onTapGesture {
                                        viewModel.flipCamera()
                                    }
                                }
                            } else {
                                EditorView(
                                    size: geo.size,
                                    data: editorData
                                )
                                .id(editorData.resetID)
                            }
                        }
                        .cornerRadius(20)
                    }

                    if viewModel.capturedImage == nil && useCameraMode {
                        VStack {
                            Spacer()

                            HStack {
                                Spacer()
                                flipCameraButton
                                    .padding(16)
                            }
                        }
                    }
                }

                Spacer()

                CameraBottomControlsView(
                    viewModel: viewModel,
                    editorData: editorData,
                    useCameraMode: $useCameraMode,
                    onSendTapped: {
                        showSendMessageSheet = true
                    }
                )
                .frame(height: 200)
            }
        }
        .toolbar {
            // LEFT → Profile
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    navManager.goToTab(id: 0)
                } label: {
                    //                    Image(systemName: "chevron.left")
                    Image(systemName: "person.circle")

                }
                .buttonStyle(.plain)

            }

            // CENTER → Title
            ToolbarItem(placement: .principal) {
                Text("Vibe Sync")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }

            // RIGHT → Inbox
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    navManager.goToTab(id: 2)
                } label: {
                    Image(systemName: "message.fill")

                }
                .buttonStyle(.plain)

            }
        }
        .onAppear {
            Task {
                await notificationManager.getAuthorizationStatus()
                showNotificationPermissionPrompt = !notificationManager
                    .hasPermission

                if useCameraMode {
                    viewModel.checkPermissions()  // will update viewModel.askForCameraPermision
                }
            }
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive {
                viewModel.stopSession()
            }
        }
        .onChange(of: useCameraMode) { _, newUseCameraMode in
            if !newUseCameraMode {
                viewModel.stopSession()

                navManager.forceSwipeEnabled = false
            } else {
                viewModel.checkPermissions()  // I use this to start the camera session - tbh can do better by refactoring this
            }
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
            Text("Please enable camera access in Settings to capture photos.")
        }
        .sheet(isPresented: $showSendMessageSheet) {
            SendVibeSheetView(
                selectedFriendIDs: $selectedFriendIDs,
                editorData: editorData
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showNotificationPermissionPrompt) {
            NotificationPermissionView()
                .environmentObject(notificationManager)
        }
        .sheet(isPresented: $viewModel.askForCameraPermision) {
            CameraPermissionView()
                .environmentObject(viewModel)
        }
        .onChange(of: notificationManager.hasPermission) { _, newValue in
            showNotificationPermissionPrompt = !newValue
        }

    }

    private var flipCameraButton: some View {
        Button {
            Task {
                viewModel.flipCamera()
            }
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
    //    NavigationStack {
    //        CameraView()
    //    }
}

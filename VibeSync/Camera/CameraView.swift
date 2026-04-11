import PhotosUI
import SwiftData
import SwiftUI

struct CameraView: View {
    @EnvironmentObject var notificationManager: APNSNotificationsManager

    @State private var viewModel = CameraViewModel()
    @State private var showNotificationPermissionPrompt = false
//    @State private var showCameraPermissionPrompt = false
    @State private var showSendMessageSheet = false
    @State private var selectedFriendIDs: Set<String> = []
    @State private var editorData = EditorData()
    @State private var useCameraMode: Bool = true  // [Camera Mode Or Canvas Mode] - By default uses Camera mode

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                CameraHeaderView()
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
                                    ).id(editorData.resetID)
                                } else {
                                    CameraPreviewView(
                                        session: viewModel.session
                                    )
                                }
                            } else {
                                EditorView(
                                    size: geo.size,
                                    data: editorData
                                )
                                .id(editorData.resetID)
                            }
                        }
                    }

                    if viewModel.capturedImage == nil && useCameraMode {
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
                    useCameraMode: $useCameraMode,
                    onSendTapped: {
                        showSendMessageSheet = true
                    }
                )
                .frame(height: 200)
            }
        }
        .onAppear {
            viewModel.checkPermissions() // will update viewModel.askForCameraPermision
            
            Task{
                await notificationManager.getAuthorizationStatus()
                Log.shared.debug("showNotificationPrompt = !notificationManager.hasPermission = \(!notificationManager.hasPermission)")
                showNotificationPermissionPrompt = !notificationManager.hasPermission
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

import PhotosUI
import SwiftData
import SwiftUI

struct CameraView: View {
    @EnvironmentObject var notificationManager: APNSNotificationsManager
    @StateObject private var viewModel = CameraViewModel()
    @State var navManager: NavigationManager = NavigationManager.shared
    
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
                                    let _ = Log.shared.debug(
                                        "if let image = viewModel.capturedImage"
                                    )
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
        .toolbar {
            // LEFT → Profile
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    navManager.goToTab(id: 0)
                } label: {
                    Image(systemName: "chevron.left")
                }
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
                    Image(systemName: "chevron.right")
                }
            }
        }
        .onAppear {
            Task {
                await notificationManager.getAuthorizationStatus()
                Log.shared.debug(
                    "showNotificationPrompt = !notificationManager.hasPermission = \(!notificationManager.hasPermission)"
                )
                showNotificationPermissionPrompt = !notificationManager
                    .hasPermission

                viewModel.checkPermissions()  // will update viewModel.askForCameraPermision
            }
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: scenePhase) {_, phase in
            switch phase {
            case .background, .inactive:
                viewModel.stopSession()
//            case .active:
//                viewModel.checkPermissions()
            @unknown default:
                break
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
    //    NavigationStack {
    //        CameraView()
    //    }
}

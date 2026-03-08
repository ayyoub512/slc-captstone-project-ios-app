//
//  CameraBottomControlsView.swift
//  VibeSync
//
//  Created by Ayyoub on 27/2/2026.
//

import PhotosUI
import SwiftUI

struct CameraBottomControlsView: View {
    @StateObject private var imageSaver = ImageSaver()
    @ObservedObject var viewModel: CameraViewModel

    @State private var showTools: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?

    @Bindable var editorData: EditorData

    @Binding var useCameraMode: Bool

    var onSendTapped: () -> Void

    var body: some View {
        VStack {

            /**
             On Camera Mode:
                 - !Captured
                     * Top: Flip Camera, Zoom, Flash
                     * Bottom: Upload, CaptureCamera, CanvasMode
                 - Captured
                     * Top: Text, Stickers, Draw tools
                     * Bottom: Undo, Send, Save
            
             On Canvas Mode:
                - !Captured
                     * Top: Draw Tools
                     * Bottom: CameraMode, CaptureCanvas
                - Captured: Show Draw tools
                    . Show Draw Tool
                         * Top: Text, Undo, Redo, Done
                         * Bottom: ToolBar
                    . !Show Draw Tool (clicked done)
                         * Top: Text, Stickers, Draw Tools
                         * Bottom: Undo, Send, Save - Gried out if !hasContenta
             */

            if useCameraMode {
                /// On Camera Mode:
                if editorData.hasContent {
                    /// Captured
                    /// * Top: Text, Stickers, Draw tools
                    HStack {
                        textButton
                        Spacer()
                        showDrawToolsButton
                    }
                    .frame(height: 70)

                    if !showTools {
                        /// * Bottom: Undo, Send, Save
                        HStack {
                            retakeButton
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .trailing
                                )

                            sendButton
                                .frame(maxWidth: .infinity, alignment: .center)

                            saveAsImageButton
                                .frame(maxWidth: .infinity, alignment: .leading)

                        }
                        .frame(height: 130)

                    } else {
                        HStack {}
                            .frame(height: 130)
                    }

                } else {
                    /// !Captured
                    /// * Top: Flip Camera, Zoom, Flash
                    HStack {
                        Text("Undo, Flip, zoom, flash")
                            .foregroundStyle(.gray)
                            .font(.footnote)
                    }
                    .frame(height: 70)

                    /// * Bottom: Upload, CaptureCamera, CanvasMode
                    HStack {
                        uploadImageButton
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        captureButton
                            .frame(maxWidth: .infinity, alignment: .center)

                        canvasModeButton
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 130)
                }

            } else {
                /// On Canvas Mode:
                ///   !Captured
                if !editorData.hasContent {
                    /// Top: Draw Tools
                    HStack {
                        Spacer()

                        showDrawToolsButton
                    }
                    .frame(height: 70)

                    if !showTools {
                        ///* Bottom: CameraMode, CaptureCanvas
                        HStack {
                            uploadImageButton
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .trailing
                                )

                            canvasCaptureButton
                                .frame(maxWidth: .infinity, alignment: .center)

                            cameraModeButton
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 130)

                    } else {
                        HStack {

                        }
                        .frame(height: 130)
                    }

                } else {
                    /// Captured: auto Show Draw tools
                    /// showDrawTool
                    if showTools {
                        /// Top: Text, Undo, Redo, Done
                        HStack {
                            textButton
                            Spacer()
                            showDrawToolsButton/// will be hide tools now
                        }
                        /// Bottom: will have ToolBar so no need to add it
                        HStack {}
                            .frame(height: 130)

                    } else {
                        /// !Show Draw Tool (clicked done)
                        /// Top: Text, Stickers, Draw Tools
                        HStack {
                            textButton
                            Spacer()
                            showDrawToolsButton
                        }

                        /// Bottom: Undo, Send, Save - Gried out if !hasContent
                        HStack {
                            retakeButton
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .trailing
                                )

                            sendButton
                                .frame(maxWidth: .infinity, alignment: .center)

                            saveAsImageButton
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 130)
                    }

                }
            }

        }

        .padding()
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)

        .onChange(of: photoItem) { oldValue, newValue in
            guard let newValue else { return }

            withAnimation {
                useCameraMode = false
            }

            Task {
                guard
                    let data = try? await newValue.loadTransferable(
                        type: Data.self
                    ),
                    let image = UIImage(data: data)
                else {
                    return
                }

                Log.shared.info("self.editorData.insertImage - upload image")
                self.editorData.insertImage(
                    image,
                    rect: .init(
                        origin: .zero,
                        size: .init(width: 200, height: 300)
                    )
                )
                photoItem = nil
            }
        }
    }

}

extension CameraBottomControlsView {

    private var captureButton: some View {
        Button {
            withAnimation {
                viewModel.capturePhoto()
            }
        } label: {
            Circle()
                .strokeBorder(.cyan, lineWidth: 5)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 68, height: 68)
                )
        }
    }

    private var sendButton: some View {
        Button {
            onSendTapped()
        } label: {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .background(
                    Circle().fill(.cyan)
                )
        }
    }

    private var textButton: some View {
        Button {
            editorData.insertText(.init("Text"), rect: .zero)
        } label: {
            Image(systemName: "t.circle")
                .cornerRadius(26)
        }
        .buttonStyle(.glass)

    }

    private var uploadImageButton: some View {
        Button {
            showImagePicker.toggle()
        } label: {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                Text("upload")
            }
        }
        .buttonStyle(.glass)

    }

    private var showDrawToolsButton: some View {
        Button {
            withAnimation {
                showTools.toggle()
                editorData.showPencilKitTools(showTools)
            }
        } label: {
            HStack {
                Text(showTools ? "Done " : "draw tools")
                Image(
                    systemName: showTools
                        ? "checkmark" : "chevron.forward"
                )
            }
        }
        .buttonStyle(.glass)

    }

    private var cameraModeButton: some View {
        Button {
            withAnimation {
                useCameraMode = true
            }
        } label: {
            Circle()
                .fill(.white)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "camera.fill")
                        .foregroundStyle(.black)
                )
        }

    }

    private var canvasModeButton: some View {
        Button {
            withAnimation {
                useCameraMode = false
            }
        } label: {
            Circle()
                .fill(.white)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "pencil.and.scribble")
                        .foregroundStyle(.black)
                )
        }

    }

    private var canvasCaptureButton: some View {
        Button {
            withAnimation {
                showTools = true
                editorData.showPencilKitTools(showTools)
            }
        } label: {
            Circle()
                .strokeBorder(.cyan, lineWidth: 5)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 68, height: 68)
                        .overlay {
                            Image(systemName: "pencil.and.scribble")
                        }
                )
        }

    }

    private var saveAsImageButton: some View {
        Button {
            Task {
                let rect = CGRect(
                    origin: .zero,
                    size: .init(width: 350, height: 670)
                )
                if let image = await editorData.exportAsImage(
                    rect,
                    scale: 2
                ) {
                    // Saving image
                    UIImageWriteToSavedPhotosAlbum(
                        image,
                        nil,
                        nil,
                        nil
                    )
                }
            }
        } label: {
            Image(systemName: "square.and.arrow.down")
                .cornerRadius(26)
        }
        .buttonStyle(.glass)

    }

    // TODO: Future feature might to make use of this
    private var saveAsDataButton: some View {
        Button("As Data", ) {
            Task {
                if let markupData = await editorData.exportAsData() {
                    print(markupData)
                }
            }
        }
    }

    private var retakeButton: some View {
        Button {
            withAnimation {
                // TODO: Difference logic here depending on weather its canvas mode or camera mode
                viewModel.retakePhoto()
                editorData.reset()

            }
        } label: {
            Image(systemName: "trash")
                .cornerRadius(26)

        }
        .buttonStyle(.glass)
    }

    private var saveButtonIconName: String {
        switch imageSaver.saveState {
        case .idle:
            return "square.and.arrow.down"
        case .saving:
            return "hourglass"
        case .success:
            return "checkmark"
        case .failure:
            return "xmark"
        }
    }

}

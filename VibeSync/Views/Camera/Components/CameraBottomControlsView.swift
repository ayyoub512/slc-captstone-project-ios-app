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
            HStack(spacing: 6) {
                Group {
                    textButton

                    Spacer()

                    showDrawToolsButton

                }
            }

            ZStack {
                HStack {
                    if viewModel.capturedImage != nil || editorData.controller != nil {
                        retakeButton
                        sendButton
                        saveAsImageButton
                    } else {
                        uploadImageButton
                        if useCameraMode {
                            captureButton
                            canvasModeButton
                        } else {
                            sendButton
                            cameraModeButton
                        }
                    }
                }
                .animation(.easeInOut, value: viewModel.capturedImage)

            }
            .padding()

        }.photosPicker(isPresented: $showImagePicker, selection: $photoItem)
            .onChange(of: photoItem) { oldValue, newValue in
                guard let newValue else { return }

                Task {
                    guard
                        let data = try? await newValue.loadTransferable(
                            type: Data.self
                        ),
                        let image = UIImage(data: data)
                    else {
                        return
                    }

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
            viewModel.capturePhoto()

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
        .padding()

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
        .padding()
    }

    private var showDrawToolsButton: some View {
        Button {
            showTools.toggle()
            editorData.showPencilKitTools(showTools)
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
        .padding()

    }

    private var cameraModeButton: some View {
        Button {
            useCameraMode = true
        } label: {
            Image(systemName: "camera.fill")
                .cornerRadius(26)
        }
        .buttonStyle(.glass)
        .padding()

    }

    private var canvasModeButton: some View {
        Button {
            useCameraMode = false
        } label: {
            Image(systemName: "pencil.and.scribble")
                .cornerRadius(26)
        }
        .buttonStyle(.glass)
        .padding()

    }

    private var saveAsImageButton: some View {
        Button("As Image", ) {
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
                viewModel.retakePhoto()
                editorData.reset()
            }
        } label: {
            Text("Trash")
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
        }
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

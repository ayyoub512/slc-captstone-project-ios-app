//
//  CameraBottomControlsView.swift
//  VibeSync
//
//  Created by Ayyoub on 27/2/2026.
//

import PhotosUI
import SwiftUI

struct CameraBottomControlsView: View {
    @ObservedObject var viewModel: CameraViewModel

    @State private var showTools: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?

    @State var editorData: EditorData

    @Binding var useCameraMode: Bool

    var onSendTapped: () -> Void

    private enum ControlState {
        case cameraIdle
        case cameraCaptured
        case canvasIdle
        case canvasDrawing  // showTools = true,  hasContent = false/true
        case canvasCaptured  // showTools = false, hasContent = true
    }

    private var controlState: ControlState {
        if useCameraMode {
            return editorData.hasContent ? .cameraCaptured : .cameraIdle
        } else {
            if editorData.hasContent {
                return showTools ? .canvasDrawing : .canvasCaptured
            } else {
                return .canvasIdle
            }
        }
    }

    var body: some View {
        VStack {
            topBar
            bottomBar
        }
        .padding()
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { _, newValue in
            guard let newValue else { return }
            withAnimation { useCameraMode = false }
            Task {
                guard
                    let data = try? await newValue.loadTransferable(
                        type: Data.self
                    ),
                    let image = UIImage(data: data)
                else { return }
                editorData.insertImage(
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

    @ViewBuilder
    private var topBar: some View {
        switch controlState {
        case .cameraIdle:
            HStack {}.frame(height: 70)

        case .cameraCaptured, .canvasCaptured:
            HStack {
                textButton
                Spacer()
                undoButton
                redoButton
                Spacer()
                showDrawToolsButton
            }
            .frame(height: 70)

        case .canvasIdle:
            HStack {
                // undoButton
                Spacer()
                showDrawToolsButton
            }
            .frame(height: 70)

        case .canvasDrawing:
            HStack {
                textButton
                Spacer()
                redoButton
                undoButton
                Spacer()
                showDrawToolsButton
            }
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        switch controlState {
        case .cameraIdle:
            HStack {
                uploadImageButton.frame(
                    maxWidth: .infinity,
                    alignment: .trailing
                )
                captureButton.frame(maxWidth: .infinity, alignment: .center)
                canvasModeButton.frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 130)

        case .cameraCaptured, .canvasCaptured:
            HStack {
                retakeButton.frame(maxWidth: .infinity, alignment: .trailing)
                sendButton.frame(maxWidth: .infinity, alignment: .center)
                saveAsImageButton.frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
            .frame(height: 130)

        case .canvasIdle:
            if showTools {
                HStack {}.frame(height: 130)
            } else {
                HStack {
                    uploadImageButton.frame(
                        maxWidth: .infinity,
                        alignment: .trailing
                    )
                    canvasCaptureButton.frame(
                        maxWidth: .infinity,
                        alignment: .center
                    )
                    cameraModeButton.frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }
                .frame(height: 130)
            }

        case .canvasDrawing:
            HStack {}.frame(height: 130)
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
                Text(showTools ? "done " : "draw tools")
                Image(
                    systemName: showTools
                        ? "checkmark" : "chevron.forward"
                )
            }
        }
        .buttonStyle(.glass)

    }

    private var undoButton: some View {
        Button {
            editorData.undo()
        } label: {
            HStack {
                Image(systemName: "arrow.uturn.backward")
            }
        }
        .buttonStyle(.glass)
    }

    private var redoButton: some View {
        Button {
            editorData.redo()
        } label: {
            HStack {
                Image(systemName: "arrow.uturn.forward")
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
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("save")
            }
        }
        .buttonStyle(.glass)

    }

    // TODO: Future feature might to make use of this
    //    private var saveAsDataButton: some View {
    //        Button("As Data", ) {
    //            Task {
    //                if let markupData = await editorData.exportAsData() {
    ////                    print(markupData)
    //                }
    //            }
    //        }
    //    }

    private var retakeButton: some View {
        Button {
            withAnimation {
                // TODO: Difference logic here depending on weather its canvas mode or camera mode
                viewModel.retakePhoto()
                editorData.reset()
            }
        } label: {

            HStack {
                Image(systemName: "trash")
                Text("retake")
            }
        }
        .buttonStyle(.glass)
    }

}

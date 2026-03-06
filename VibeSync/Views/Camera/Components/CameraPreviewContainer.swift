//
//  CameraPreviewContainer.swift
//  VibeSync
//
//  Created by Ayyoub on 27/2/2026.
//

import SwiftUI

struct CameraPreviewContainer: View {
    @ObservedObject var viewModel: CameraViewModel
    @Binding var isEditingText: Bool

    var body: some View {
        ZStack {
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        if let image = viewModel.capturedImage {
                            ComposableImageView(
                                image: image,
                                overlayText: viewModel.overlayText
                            )
                            .overlay(alignment: .bottom) {
                                // EditableLabel sits on top for interaction only
                                // it doesn't affect what gets rendered
                                HStack {
                                    EditableLabel(
                                        $viewModel.overlayText,
                                        isEditing: $isEditingText
                                    ) {}
//                                    .font(.title2)
//                                    .foregroundStyle(.clear)  // invisible — ComposableImageView draws the text
//                                    .fixedSize()
                                }
//                                .padding()
//                                .frame(height: geo.size.height)
                            }

                        } else {
                            CameraPreviewView(session: viewModel.session)
                        }
                    }
                    .frame(height: geo.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

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
        }
//        .frame(height: 400)
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


public struct EditableLabel: View {
    @Binding var text: String
    @Binding var isEditing: Bool

    @State private var newValue: String = ""
    @FocusState private var isFocused: Bool

    let onEditEnd: () -> Void

    public init(
        _ txt: Binding<String>,
        isEditing: Binding<Bool>,
        onEditEnd: @escaping () -> Void
    ) {
        _text = txt
        _isEditing = isEditing
        self.onEditEnd = onEditEnd
    }

    public var body: some View {
        ZStack {
            Text(text)
                .opacity(isEditing ? 0 : 1)
                .foregroundStyle(.white)

            // TextField for edit mode of View
            TextField(
                "",
                text: $newValue,
                onCommit: commit
            )
            .multilineTextAlignment(.center)
            .opacity(isEditing ? 1 : 0)
            .focused($isFocused)
        }
        .onTapGesture {
            newValue = text
            isEditing = true
            isFocused = true
        }
        // Exit from EditMode on Esc key press
        .onChange(
            of: isEditing,
            { oldIsEditing, newIsEditing in
                if !newIsEditing {
                    isFocused = false
                    commit()
                }
            }
        )
        .onChange(of: isFocused) { oldIsfocused, newIsFocused in
            if !newIsFocused && isEditing {
                commit()
            }
        }
    }

    private func commit() {
        text = newValue
        isEditing = false
        onEditEnd()
    }
}

struct ComposableImageView: View {
    let image: UIImage
    let overlayText: String

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .overlay(alignment: .bottom) {
                if !overlayText.isEmpty {
                    HStack {
                        Text(overlayText)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.black.opacity(0.6))
                            )
                            .fixedSize()
                    }
                    .padding()
                }
            }
    }
}

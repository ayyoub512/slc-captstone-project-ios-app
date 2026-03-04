//
//  CameraPreviewContainer.swift
//  VibeSync
//
//  Created by Ayyoub on 27/2/2026.
//

import SwiftUI

struct CameraPreviewContainer: View {
    @ObservedObject var viewModel: CameraViewModel

    // Label overlay
    @State private var label: String = "Hi"
    @State private var isEditingText = false

    var body: some View {
        ZStack {
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        if let image = viewModel.capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .overlay {
                                    VStack {
                                        Spacer()
                                        HStack{
                                            EditableLabel(
                                                $label,
                                                isEditing: $isEditingText
                                            ) {
                                                print(
                                                    "Editing ended. New username: \(label)"
                                                )
                                            }
                                            .font(.title2)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 24)
                                                    .fill(Color.black.opacity(0.6))
                                            )
                                            .fixedSize()
                                        } .padding()  // padding from the image edges
                                    }
                                    .frame(
                                        width: geo.size.width,
                                        height: geo.size.height,
                                        alignment: .bottom
                                    )
                                   

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
        .frame(height: 400)
        .onTapGesture {
            if isEditingText {
                print("Clicked away while isEditingText=true")
                isEditingText = false
            }
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
        .onChange(of: isEditing, { oldIsEditing, newIsEditing in
            if !newIsEditing {
                isFocused = false
                commit()
            }
        })
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

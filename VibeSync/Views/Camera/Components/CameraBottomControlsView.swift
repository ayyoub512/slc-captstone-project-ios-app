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

    var editorData: EditorData

    var onSendTapped: () -> Void

    var body: some View {
        VStack{
            HStack(spacing: 6){
                Group{
                    Button("Text") {
                        editorData.insertText(.init("Text"), rect: .zero)
                    }
                    
                    Button("Image") {
                        showImagePicker.toggle()
                    }
                    
                    Button(showTools ? "Hide" : "Show") {
                        showTools.toggle()
                        editorData.showPencilKitTools(showTools)
                    }
                }
                .buttonStyle(.glass)
                .padding()
                
                Menu("Save"){
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
                                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            }
                        }
                    }
                    
                    Button("As Data", ) {
                        Task {
                            if let markupData = await editorData.exportAsData() {
                                print(markupData)
                            }
                        }
                    }
                }
                .buttonStyle(.glass)
                
            }
            
            ZStack {
                Group {
                    if viewModel.capturedImage != nil {
                        sendButton
                    } else {
                        captureButton
                    }
                }
                .animation(.easeInOut, value: viewModel.capturedImage)
                
                HStack {
                    if viewModel.capturedImage != nil {
                        saveButtom
                        Spacer()
                        retakeButton
                    } else {
                        Spacer()
                    }
                }
            }
            .padding()
            
            
        }.photosPicker(isPresented: $showImagePicker, selection: $photoItem)
            .onChange(of: photoItem) { oldValue, newValue in
                guard let newValue else {return}
                
                Task {
                    guard let data = try? await newValue.loadTransferable(type: Data.self),
                          let image = UIImage(data: data)
                    else {
                        return
                    }
                    
                    self.editorData.insertImage(image, rect: .init(origin: .zero, size: .init(width: 200, height: 300)))
                    photoItem = nil
                }
            }
    }

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

    private var retakeButton: some View {
        Button {
            withAnimation {
                viewModel.retakePhoto()
            }
        } label: {
            Text("Retake")
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
        }
    }

    private var saveButtom: some View {
        Button {
            guard let capturedImage = viewModel.capturedImage else {
                print(
                    "saveButtom - Error cant save this image, cant unwrap. returning."
                )
                return
            }
            imageSaver.writeToPhotoAlbum(image: capturedImage)

        } label: {
            Image(systemName: saveButtonIconName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .padding()
                .background(.white.opacity(0.2))
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

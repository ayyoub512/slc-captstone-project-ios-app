//
//  CameraBottomControlsView.swift
//  VibeSync
//
//  Created by Ayyoub on 27/2/2026.
//

import SwiftUI

struct CameraBottomControlsView: View {
    @StateObject private var imageSaver = ImageSaver()
    @ObservedObject var viewModel: CameraViewModel
    var onSendTapped: () -> Void

    var body: some View {
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
                }else{
                    Spacer()
                }
            }
        }
        .padding()
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
                print("saveButtom - Error cant save this image, cant unwrap. returning.")
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

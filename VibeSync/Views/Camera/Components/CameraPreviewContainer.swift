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

//
//  CameraPreviewContainer.swift
//  VibeSync
//
//  Created by Ayyoub on 27/2/2026.
//

import SwiftUI

struct CameraPreviewContainer: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.gray.opacity(0.2))
                .overlay {
                    if let image = viewModel.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        CameraPreviewView(session: viewModel.session)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))

            if viewModel.capturedImage == nil {
                VStack {
                    HStack {
                        Spacer()
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
                    Spacer()
                }
            }
        }
        .frame(height: 520)
    }
}

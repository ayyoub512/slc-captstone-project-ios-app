//
//  CameraBottomControlsView.swift
//  VibeSync
//
//  Created by Ayyoub on 27/2/2026.
//

import SwiftUI

struct CameraBottomControlsView: View {
    @ObservedObject var viewModel: CameraViewModel
    var onSendTapped: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            if viewModel.capturedImage != nil {
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

                Button {
                    onSendTapped()
                } label: {
                    Text("Send")
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }

            } else {
                Button {
                    viewModel.capturePhoto()
                } label: {
                    Circle()
                        .strokeBorder(Color.cyan, lineWidth: 5)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 68, height: 68)
                        )
                }
            }
        }
    }
}

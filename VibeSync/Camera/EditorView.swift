//
//  EditorView.swift
//  VibeSync
//
//  Created by Ayyoub on 6/3/2026.
//

import PaperKit
import SwiftUI

// Update EditorView to show immediate feedback
struct EditorView: View {
    var size: CGSize
    @Bindable var data: EditorData
    var image: UIImage?

    @State private var isProcessing = false
    @State private var imageToInsert: UIImage?

    var body: some View {
        ZStack {
            Group {
                if let controller = data.controller {
                    PaperControllerView(controller: controller)
                } else {
                    ProgressView("Initializing...")
                }
            }

        
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.3)
                    ProgressView("Processing image...")
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                }
            }
        }
        .onAppear {
            Log.shared.debug("EditorView.onAppear")

            data.initializeController(.init(origin: .zero, size: size))
            Task {
                    await data.waitForController()

                    if let userImage = image {
                        data.insertBackground(
                            userImage,
                            rect: .init(origin: .zero, size: size)
                        )
                    }
                }
            
            data.viewSize = size
        }
        .onChange(of: data.isControllerReady) { _, isReady in
            // ✅ Insert image when controller is ready
            if isReady, let userImage = imageToInsert {
                isProcessing = true
                Task {
                    data.insertBackground(
                        userImage,
                        rect: .init(origin: .zero, size: size)
                    )
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    isProcessing = false
                    imageToInsert = nil
                }
            }
        }
    }
}



// Paper controller View
private struct PaperControllerView: UIViewControllerRepresentable {
    var controller: PaperMarkupViewController
    func makeUIViewController(context: Context) -> PaperMarkupViewController {
        //        controller.contentView?.backgroundColor = .red
        
        return controller
    }

    func updateUIViewController(
        _ uiViewController: PaperMarkupViewController,
        context: Context
    ) {

    }

}

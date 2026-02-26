//
//  DrawingHelper.swift
//  VibeSync
//
//  Created by Ayyoub on 25/2/2026.
//

import PencilKit
import SwiftUI

// Helper class for saving images
class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(saveCompleted(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }

    @objc func saveCompleted(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer?
    ) {
        if let error = error {
            print("Error saving image: \(error.localizedDescription)")
        } else {
            print("Image saved successfully!")
        }
    }
}

struct CanvasView: UIViewRepresentable {
//    @Binding var canvasView: PKCanvasView
    var isVisible: Bool

    var onCanvasReady: (PKCanvasView) -> Void

    
    // Coordinator holds the toolPicker so it survives struct re-creation
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        let canvas = PKCanvasView()
        let toolPicker = PKToolPicker()
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = context.coordinator.canvas
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        
        DispatchQueue.main.async{
            onCanvasReady(canvasView)
        }
        
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        let toolPicker = context.coordinator.toolPicker
        
        if isVisible {
            toolPicker.addObserver(uiView)
            toolPicker.setVisible(true, forFirstResponder: uiView)

            if !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            }
        } else {
            toolPicker.setVisible(false, forFirstResponder: uiView)
            toolPicker.removeObserver(uiView)
            uiView.resignFirstResponder()
        }
    }

}

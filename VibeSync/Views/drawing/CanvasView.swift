//
//  CanvasView.swift
//  VibeSync
//
//  Created by Ayyoub on 11/2/2026.
//

import PencilKit
import SwiftUI

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    private let toolPicker = PKToolPicker()

    func makeUIView(context: Context) -> PKCanvasView {
        // Allow finger drawing
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)

        // Make the canvas active -- first responder
        canvasView.becomeFirstResponder()

        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        //        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }

}

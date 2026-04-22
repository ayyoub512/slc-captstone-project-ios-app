//
//  EditorData.swift
//  VibeSync
//
//  Created by Ayyoub on 6/3/2026.
//

import Combine
import PaperKit
import PencilKit
import SwiftUI

final class MarkupObserver: NSObject, PaperMarkupViewController.Delegate {

    var onCanvasChanged: (() -> Void)?

    func paperMarkupViewControllerDidChangeMarkup(
        _ paperMarkupViewController: PaperMarkupViewController
    ) {
        onCanvasChanged?()
    }

    func paperMarkupViewControllerDidBeginDrawing(
        _ paperMarkupViewController: PaperMarkupViewController
    ) {

    }

    func paperMarkupViewControllerDidChangeSelection(
        _ paperMarkupViewController: PaperMarkupViewController
    ) {

    }

    func paperMarkupViewControllerDidChangeContentVisibleFrame(
        _ paperMarkupViewController: PaperMarkupViewController
    ) {

    }
}

@Observable
class EditorData {
    var controller: PaperMarkupViewController?
    var toolPicker = PKToolPicker()
    var viewSize: CGSize?
    var hasContent: Bool = false
    var resetID = UUID()
    var canvaSizeRect: CGRect?

    var isControllerReady = false

    private let observer = MarkupObserver()

    func initializeController(_ rect: CGRect) {
        Log.shared.debug("initializeController rect: \(rect)")
        guard controller == nil else {
            Log.shared.error(
                "[WARNING: EditorData intializeController] Intialize Controller error: guard controller == nil else {}"
            )
            return
        }
        canvaSizeRect = rect
        viewSize = rect.size // keep both in sync

        let newController = PaperMarkupViewController(
            supportedFeatureSet: .latest
        )
        newController.markup = PaperMarkup(bounds: rect)
        newController.zoomRange = 0.8...1.5

        newController.delegate = self.observer
        self.observer.onCanvasChanged = { [weak self] in
            self?.hasContent = true
        }
        self.controller = newController
        self.isControllerReady = true  //  Set flag
    }

    private func makeController(_ rect: CGRect) {
        let newController = PaperMarkupViewController(
            supportedFeatureSet: .latest
        )
        newController.markup = PaperMarkup(bounds: rect)
        newController.zoomRange = 0.8...1.5

        newController.delegate = observer
        observer.onCanvasChanged = { [weak self] in
            self?.hasContent = true
        }

        self.controller = newController
    }

    // markup editing methods

    func insertText(_ text: NSAttributedString, rect: CGRect) {
        controller?.markup?.insertNewTextbox(attributedText: text, frame: rect)
    }

    func modelCanUndo() -> Bool {

        return controller?.undoManager?.canUndo ?? false
    }

    func modelCanRedo() -> Bool {
        return controller?.undoManager?.canRedo ?? false
    }

    func undo() {
        controller?.undoManager?.undo()
    }

    func redo() {
        controller?.undoManager?.redo()
    }

    @MainActor
    func waitForController() async {
        while controller == nil {
            try? await Task.sleep(nanoseconds: 20_000_000)
            Log.shared.info(
                "[WARNING: EditorData waitForController]  waitForController After sleep"
            )
        }
    }

    // Update EditorData.insertBackground
    func insertBackground(_ image: UIImage, rect: CGRect) {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            //  1. Resize image FIRST (on background thread)
            let maxDimension: CGFloat = 2000  // Max 2000px - plenty for display
            let resizedImage = image.resizedToFit(maxDimension: maxDimension)

            //  2. Fix orientation (on background thread)
            guard let normalizedImage = resizedImage.fixedOrientation(),
                let cgImage = normalizedImage.cgImage
            else {
                await Log.shared.error(
                    "F[WARNING: EditorData - insertBackground]  Failed to process image"
                )
                return
            }

            //  3. Calculate draw rect
            let canvasSize = rect.size
            let imageSize = normalizedImage.size
            let imageAspect = imageSize.width / imageSize.height
            let canvasAspect = canvasSize.width / canvasSize.height

            let drawRect: CGRect
            if imageAspect > canvasAspect {
                let height = canvasSize.height
                let width = height * imageAspect
                let x = (canvasSize.width - width) / 2
                drawRect = CGRect(x: x, y: 0, width: width, height: height)
            } else {
                let width = canvasSize.width
                let height = width / imageAspect
                let y = (canvasSize.height - height) / 2
                drawRect = CGRect(x: 0, y: y, width: width, height: height)
            }

            // 4. Insert on main thread
            await MainActor.run {
                self.controller?.markup?.insertNewImage(
                    cgImage,
                    frame: drawRect
                )
            }
        }
    }

    func insertImage(_ image: UIImage, rect: CGRect) {
        guard let cgImage = image.cgImage else { return }

        controller?.markup?.insertNewImage(cgImage, frame: rect)
    }

    func insertShape(_ type: ShapeConfiguration, rect: CGRect) {
        controller?.markup?.insertNewShape(configuration: type, frame: rect)
    }

    func showPencilKitTools(_ isVisible: Bool) {
        guard let controller else { return }

        // Type 1
        //controller.view.pencilKitResponderState.activeToolPicker = toolPicker
        //controller.view.pencilKitResponderState.toolPickerVisibility = isVisible ? .visible : .hidden

        // Type 2 - More stuff i.e text, shapes
        toolPicker.addObserver(controller)
        toolPicker.setVisible(isVisible, forFirstResponder: controller.view)

        if isVisible {
            controller.view.becomeFirstResponder()
        }

    }

    func reset() {

        // 1. Clean up tool picker
        if let controller = controller {
            toolPicker.removeObserver(controller)
            toolPicker.setVisible(false, forFirstResponder: controller.view)
            controller.view.resignFirstResponder()
        }

        // 2. Clear controller
        controller = nil

        // 3. Reset state (keep canvaSizeRect!)
        hasContent = false
        // canvaSizeRect = nil  //

        // 4. Generate new reset ID to force SwiftUI recreation
        resetID = UUID()
    }

    // markup to Data/Image
//    func exportAsImage(_ rect: CGRect, scale: CGFloat = 2) async -> UIImage? {
//
//        // 1. Dismiss any active tools so pending strokes are committed
//        await MainActor.run {
//            controller?.view.resignFirstResponder()
//            toolPicker.setVisible(
//                false,
//                forFirstResponder: controller?.view ?? UIView()
//            )
//        }
//
//        // 2. Give PaperKit a tick to flush pending markup changes
//        try? await Task.sleep(for: .milliseconds(150))
//
//        guard let context = makeCGContext(size: rect.size, scale: scale),
//            let markup = controller?.markup
//        else {
//            Log.shared.error(
//                "[ERROR: EditorData - exportAsImage]: guard let context = makeCGContext(size: rec "
//            )
//            return nil
//        }
//
//        await markup.draw(in: context, frame: rect)
//        guard let cgImage = context.makeImage() else {
//            Log.shared.error(
//                "[ERROR: EditorData - exportAsImage] - guard let cgImage = context.makeImage() else {"
//            )
//            return nil
//        }
//
//        return UIImage(cgImage: cgImage)
//    }
    
    @MainActor
    func exportAsImage(_ rect: CGRect, scale: CGFloat = 2) async -> UIImage? {
        guard let controller = controller else { return nil }

        // Commit any active editing
        controller.view.endEditing(true)
        controller.view.resignFirstResponder()
        toolPicker.setVisible(false, forFirstResponder: controller.view)

        
        // Deselect any selected annotation to hide the selection UI - I found the solution is by setting isEditable false temporarily
        controller.isEditable = false
        
        // Let PaperKit finish its render cycle
        try? await Task.sleep(for: .milliseconds(200))

        // Snapshot the live view — this captures EXACTLY what the user sees
        let renderer = UIGraphicsImageRenderer(
            size: rect.size,
            format: {
                let fmt = UIGraphicsImageRendererFormat()
                fmt.scale = scale
                fmt.opaque = true
                return fmt
            }()
        )

        let image = renderer.image { ctx in
            // Fill white background first
            UIColor.white.setFill()
            ctx.fill(rect)
            
            // Render the controller's view hierarchy
            controller.view.drawHierarchy(in: rect, afterScreenUpdates: true)
        }
        
        controller.isEditable = true
        return image
    }

    func exportAsData() async -> Data? {
        do {
            return try await controller?.markup?.dataRepresentation()
        } catch {
            Log.shared.error(error.localizedDescription)
            return nil
        }
    }

    // Creating a CGContext
    private func makeCGContext(size: CGSize, scale: CGFloat) -> CGContext? {
        let width = Int(size.width * scale)
        let height = Int(size.height * scale)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            )
        else { return nil }

        context.scaleBy(x: scale, y: scale)

        // Flip coordinates for CoreGraphics
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)

        // Fill with white background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        return context
    }
}

// Helper to fix orientation
extension UIImage {
    nonisolated func fixedOrientation() -> UIImage? {
        guard imageOrientation != .up else { return self }

        // Use CIImage - MUCH faster than UIGraphics
        guard let ciImage = CIImage(image: self) else { return self }

        let transform: CGAffineTransform
        switch imageOrientation {
        case .down, .downMirrored:
            transform = CGAffineTransform(rotationAngle: .pi)
        case .left, .leftMirrored:
            transform = CGAffineTransform(rotationAngle: .pi / 2)
        case .right, .rightMirrored:
            transform = CGAffineTransform(rotationAngle: -.pi / 2)
        default:
            return self
        }

        let oriented = ciImage.transformed(by: transform)
        let context = CIContext(options: nil)
        guard
            let cgImage = context.createCGImage(oriented, from: oriented.extent)
        else {
            return self
        }

        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }

    nonisolated func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let scale = maxDimension / max(size.width, size.height)
        if scale >= 1 { return self }

        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

extension NSAttributedString {
    func centerRect(in rect: CGRect) -> CGRect {
        let textSize = self.size()
        let textCenter = CGPoint(
            x: rect.midX - (textSize.width / 2),
            y: rect.midY - (textSize.height / 2)
        )

        return CGRect(origin: textCenter, size: textSize)
    }
}

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

    // Update EditorData
    func initializeController(_ rect: CGRect) {
        Log.shared.debug("initializeController rect: \(rect)")
        guard controller == nil else { return }
        canvaSizeRect = rect

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            let newController = PaperMarkupViewController(
                supportedFeatureSet: .latest
            )
            newController.markup = PaperMarkup(bounds: rect)
            newController.zoomRange = 0.8...1.5

            await MainActor.run {
                newController.delegate = self.observer
                self.observer.onCanvasChanged = { [weak self] in
                    self?.hasContent = true
                }
                self.controller = newController
                self.isControllerReady = true  // ✅ Set flag
                Log.shared.debug("✅ Controller initialized and ready")
            }
        }
    }

    //    func initializeController(_ rect: CGRect) {
    //        Log.shared.debug("initializeController rect: \(rect)")
    //        guard controller == nil else { return }
    //        canvaSizeRect = rect
    //        makeController(rect)
    //    }

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

    // Update EditorData.insertBackground
    func insertBackground(_ image: UIImage, rect: CGRect) {
        Log.shared.debug("insertBackground START")

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            // ✅ 1. Resize image FIRST (on background thread)
            let maxDimension: CGFloat = 2000  // Max 2000px - plenty for display
            let resizedImage = image.resizedToFit(maxDimension: maxDimension)

            // ✅ 2. Fix orientation (on background thread)
            guard let normalizedImage = resizedImage.fixedOrientation(),
                let cgImage = normalizedImage.cgImage
            else {
                Log.shared.error("Failed to process image")
                return
            }

            // ✅ 3. Calculate draw rect
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

            // ✅ 4. Insert on main thread
            await MainActor.run {
                self.controller?.markup?.insertNewImage(
                    cgImage,
                    frame: drawRect
                )
                Log.shared.debug("insertBackground COMPLETE")
            }
        }
    }

    //    func insertBackground(_ image: UIImage, rect: CGRect) {
    //        Log.shared.debug(
    //            "insertBackground rect: \(rect), imageSize: \(image.size)"
    //        )
    //
    //        guard let normalizedImage = image.fixedOrientation(),
    //            let cgImage = normalizedImage.cgImage
    //        else { return }
    //
    //        let canvasSize = rect.size
    //        let imageSize = normalizedImage.size
    //
    //        let imageAspect = imageSize.width / imageSize.height
    //        let canvasAspect = canvasSize.width / canvasSize.height
    //
    //        var drawRect = CGRect.zero
    //
    //        if imageAspect > canvasAspect {
    //            // Image is wider than canvas → scale width, crop horizontally
    //            let height = canvasSize.height
    //            let width = height * imageAspect
    //            let x = (canvasSize.width - width) / 2
    //            drawRect = CGRect(x: x, y: 0, width: width, height: height)
    //        } else {
    //            // Image is taller than canvas → scale height, crop vertically
    //            let width = canvasSize.width
    //            let height = width / imageAspect
    //            let y = (canvasSize.height - height) / 2
    //            drawRect = CGRect(x: 0, y: y, width: width, height: height)
    //        }
    //
    //        controller?.markup?.insertNewImage(cgImage, frame: drawRect)
    //    }

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
        Log.shared.debug("Resetting EditorData")

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
        // ✅ DON'T clear canvaSizeRect - keep it for recreation
        // canvaSizeRect = nil  // ❌ Remove this line

        // 4. Generate new reset ID to force SwiftUI recreation
        resetID = UUID()

        Log.shared.debug(
            "EditorData reset complete - SwiftUI will recreate view"
        )
    }

    // markup to Data/Image
    func exportAsImage(_ rect: CGRect, scale: CGFloat = 2) async -> UIImage? {
        guard let context = makeCGContext(size: rect.size, scale: scale),
            let markup = controller?.markup
        else {
            Log.shared.error(
                "Error - guard let context = makeCGContext(size: rec "
            )
            return nil
        }

        await markup.draw(in: context, frame: rect)
        guard let cgImage = context.makeImage() else {
            Log.shared.error(
                "Error - guard let cgImage = context.makeImage() else {"
            )
            return nil
        }

        return UIImage(cgImage: cgImage)
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
    func fixedOrientation() -> UIImage? {
        guard imageOrientation != .up else { return self }

        // ✅ Use CIImage - MUCH faster than UIGraphics
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

    func resized(to targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    // ✅ Smart resize that maintains aspect ratio
    func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let scale = maxDimension / max(size.width, size.height)
        if scale >= 1 { return self }  // Already small enough

        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        return resized(to: newSize) ?? self
    }

    //    func fixedOrientation() -> UIImage? {
    //        guard imageOrientation != .up else { return self }
    //        UIGraphicsBeginImageContextWithOptions(size, false, scale)
    //        draw(in: CGRect(origin: .zero, size: size))
    //        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
    //        UIGraphicsEndImageContext()
    //        return normalizedImage
    //    }
}

// Calculating center rect wuth the given rect!

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

//
//  EditorData.swift
//  VibeSync
//
//  Created by Ayyoub on 6/3/2026.
//

import PaperKit
import PencilKit
import SwiftUI
import Combine

final class MarkupObserver: NSObject, PaperMarkupViewController.Delegate {

    var onCanvasChanged: (() -> Void)?

    func paperMarkupViewControllerDidChangeMarkup(_ paperMarkupViewController: PaperMarkupViewController) {
        onCanvasChanged?()
    }
    
    func paperMarkupViewControllerDidBeginDrawing(_ paperMarkupViewController: PaperMarkupViewController) {

    }
    
    func paperMarkupViewControllerDidChangeSelection(_ paperMarkupViewController: PaperMarkupViewController) {

    }
    
    func paperMarkupViewControllerDidChangeContentVisibleFrame(_ paperMarkupViewController: PaperMarkupViewController) {

    }
}

@Observable
class EditorData {
    var controller: PaperMarkupViewController?
    var toolPicker = PKToolPicker()
    var viewSize: CGSize?
    var hasContent: Bool = false
    var resetID = UUID()

    private let observer = MarkupObserver()

    func initializeController(_ rect: CGRect) {
        Log.shared.debug("initializeController rect: \(rect)")
        guard controller == nil else { return }
        
        makeController(rect)
    }
    
    private func makeController(_ rect:CGRect){
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

    func insertBackground(_ image: UIImage, rect: CGRect) {
        Log.shared.debug(
            "insertBackground rect: \(rect), imageSize: \(image.size)"
        )

        guard let normalizedImage = image.fixedOrientation(),
            let cgImage = normalizedImage.cgImage
        else { return }

        let canvasSize = rect.size
        let imageSize = normalizedImage.size

        let imageAspect = imageSize.width / imageSize.height
        let canvasAspect = canvasSize.width / canvasSize.height

        var drawRect = CGRect.zero

        if imageAspect > canvasAspect {
            // Image is wider than canvas → scale width, crop horizontally
            let height = canvasSize.height
            let width = height * imageAspect
            let x = (canvasSize.width - width) / 2
            drawRect = CGRect(x: x, y: 0, width: width, height: height)
        } else {
            // Image is taller than canvas → scale height, crop vertically
            let width = canvasSize.width
            let height = width / imageAspect
            let y = (canvasSize.height - height) / 2
            drawRect = CGRect(x: 0, y: y, width: width, height: height)
        }

        controller?.markup?.insertNewImage(cgImage, frame: drawRect)
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
        controller = nil
        hasContent = false
        resetID = UUID() /// Uniquly identifies
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
        //let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue // Dont use the Alpha channel
        
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
        else {
            return nil
        }

        context.scaleBy(x: scale, y: scale)

        // Flipping the image
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        return context
    }
}

// Helper to fix orientation
extension UIImage {
    func fixedOrientation() -> UIImage? {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage
    }
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

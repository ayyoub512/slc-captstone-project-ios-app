//
//  EditorView.swift
//  VibeSync
//
//  Created by Ayyoub on 6/3/2026.
//

import PaperKit
import SwiftUI

struct EditorView: View {

    var size: CGSize
    @Bindable var data: EditorData
    var image: UIImage?

    var body: some View {
        Group {
            if let controller = data.controller {
                PaperControllerView(controller: controller)

            } else {
                ProgressView()
            }
        }
        .onAppear {
            Log.shared.debug("On appear: Calling .initializeController")
            guard data.controller == nil else {return}
            data.initializeController(.init(origin: .zero, size: size))
            data.viewSize = size
            if let userImage = image {
                data.insertBackground(
                    userImage,
                    rect: .init(origin: .zero, size: size)
                )
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

#Preview {
    DrawingContentViewYT()
}

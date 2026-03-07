//
//  EditorView.swift
//  VibeSync
//
//  Created by Ayyoub on 6/3/2026.
//

import SwiftUI
import PaperKit

struct EditorView: View {
    
    var size: CGSize
    @State var data: EditorData
    var image: UIImage?
    
//    init(size: CGSize, editorData: EditorData, image: UIImage?){
//        self.size = size
//        self._data = .init(initialValue: editorData)
//        self.image = image
////        self.data.viewSize = size
//    }
    
    var body: some View {
        if let controller = data.controller{
            PaperControllerView(controller: controller)
        
        }else{
            ProgressView()
                .onAppear{
                    data.initializeController(.init(origin: .zero, size: size))
                    if let userImage = image {
                        data.insertBackground(userImage, rect: .init(origin: .zero, size: size))
                    }
                }
        }
    }
}

// Paper controller View
fileprivate struct PaperControllerView: UIViewControllerRepresentable {
    var controller: PaperMarkupViewController
    func makeUIViewController(context: Context) -> PaperMarkupViewController {
//        controller.contentView?.backgroundColor = .red
        return controller
    }
    
    
    func updateUIViewController(_ uiViewController: PaperMarkupViewController, context: Context) {
        
    }
}

#Preview {
    DrawingContentViewYT()
}

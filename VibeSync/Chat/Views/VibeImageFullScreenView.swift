//
//  VibeImageFullScreenView.swift
//  VibeSync
//
//  Created by Ayyoub on 15/4/2026.
//

import SwiftUI

struct VibeImageFullScreenView: View {
    @Environment(\.dismiss) private var dismiss
    var message: VibeMessage
    @State private var model: VibeImageFullScreenViewModel

    init(message: VibeMessage) {
        self.message = message
        _model = State(
            wrappedValue: VibeImageFullScreenViewModel(
                imageURL: message.imageURL
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack {
                if let img = model.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                }else {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Text(message.created_at)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        model.saveImage()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: saveIconName)
                            Text("Save Photo")
                        }
                    }
                }
            }

        }
    }

    private var saveIconName: String {
        switch model.saveState {
        case .idle:
            return "square.and.arrow.down"
        case .saving:
            return "hourglass"
        case .success:
            return "checkmark"
        case .failure:
            return "xmark"
        }
    }

}

#Preview {
    VibeImageFullScreenView(
        message: VibeMessage(
            _id: "asd",
            senderID: "123",
            receiverID: "345",
            imageURL: "https://vibesync.ayyoub.io/imgs/camera.png",
            resizedImageURL: "https://vibesync.ayyoub.io/imgs/camera.png",
            created_at: "2026-04-15T14:32:10.123Z"
        )
    )
}

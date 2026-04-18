//
//  ChatImageView.swift
//  VibeSync
//
//  Created by Ayyoub on 9/3/2026.
//

import SwiftUI

struct ChatImageView: View {
    @State var model: ChatImageViewModel

    let message: VibeMessage
    @State private var showImageFullScreen = false

    init(for message: VibeMessage) {
//        Log.shared.debug("[ChatImageView - init]: \(message)")

        _model = State(
            wrappedValue: ChatImageViewModel(
                key: message.id,
                url: message.resizedImageURL
            )
        )
        self.message = message
    }

    var body: some View {
        VStack {
            if model.isLoading {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 240, height: 320)
                    .overlay { ProgressView() }

            } else if let image = model.image {
                Image(uiImage: image).resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 240, height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
                    .onLongPressGesture(minimumDuration: 0.4) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showImageFullScreen = true
                    }
                    .onTapGesture {
                        showImageFullScreen = true
                    }
            }
        }
        .frame(width: 240, height: 320) // stable layout immediately
        .task {
            await model.getImage()
        }
        .sheet(isPresented: $showImageFullScreen) {
            VibeImageFullScreenView(message: message)
                .presentationDetents([.large])
        }
    }
}

#Preview {
    //    ChatImageView()
}



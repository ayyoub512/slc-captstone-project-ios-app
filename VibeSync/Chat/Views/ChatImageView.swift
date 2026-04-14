//
//  ChatImageView.swift
//  VibeSync
//
//  Created by Ayyoub on 9/3/2026.
//

import SwiftUI

struct ChatImageView: View {
    @State var model: ChatImageViewModel
    let url: String

    init(url: String, key: String) {
        _model = State(wrappedValue: ChatImageViewModel(key: key, url: url))
        self.url = url
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
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
            }
        }
        .task {
            await model.getImage()
        }

    }
}

#Preview {
    //    ChatImageView()
}

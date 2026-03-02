//
//  VibeImageBubble.swift
//  VibeSync
//
//  Created by Ayyoub on 25/2/2026.
//

import SwiftUI

struct VibeImageBubble: View {
    let url: String
    let isFromMe: Bool
    
    var body: some View {
        HStack {
            if isFromMe { Spacer() }
            
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .empty:
                    // While loading
                    ZStack {
                        Color.gray.opacity(0.1)
                        ProgressView()
                    }
                    .frame(width: 240, height: 320)
                case .success(let image):
                    // On success
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 240, height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                case .failure:
                    // If image link fails
                    ZStack {
                        Color.red.opacity(0.1)
                        Image(systemName: "photo.badge.exclamationmark")
                            .foregroundStyle(.red)
                    }
                    .frame(width: 240, height: 320)
                @unknown default:
                    EmptyView()
                }
            }
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
            
            if !isFromMe { Spacer() }
        }
        .padding(.horizontal)
    }
}

//#Preview {
//    VibeImageBubble()
//}

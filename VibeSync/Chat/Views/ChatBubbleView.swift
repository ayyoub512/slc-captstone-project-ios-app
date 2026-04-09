//
//  VibeImageBubble.swift
//  VibeSync
//
//  Created by Ayyoub on 25/2/2026.
//

import SwiftUI

struct ChatBubbleView: View {
    let message: VibeMessage
    let isFromMe: Bool
    
    var body: some View {
        VStack{
            HStack {
                if isFromMe { Spacer() }
                
                ChatImageView(url: message.imageURL, key: message.id)
                
                if !isFromMe { Spacer() }
            }
            .padding(.horizontal)
            
            HStack{
                if isFromMe { Spacer() }
                
                Text("\(message.created_at)")
                    .font(.footnote)
                    .padding(.horizontal)
            }
        }
    }
}

//#Preview {
//    VibeImageBubble()
//}

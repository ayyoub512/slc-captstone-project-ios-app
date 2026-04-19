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
                
                ChatImageView(for: message)
                
                if !isFromMe { Spacer() }
            }
            .padding(.horizontal)
            
            HStack{
                if isFromMe { Spacer() }
                
                Text("\(message.createdAt.formattedMessageDate)")
                    .font(.footnote)
                    .padding(.horizontal)
            }
        }
    }
}

extension String {
    var formattedMessageDate: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: self) else { return self }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        // Show date too if not today
        if !Calendar.current.isDateInToday(date) {
            formatter.dateStyle = .short
        }
        return formatter.string(from: date)
    }
}

//#Preview {
//    VibeImageBubble()
//}

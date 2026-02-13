//
//  LocalNotification.swift
//  VibeSync
//
//  Created by Ayyoub on 12/2/2026.
//

import SwiftUI

class NotificationManager{
    static let instance = NotificationManager() // Singleton
}


struct LocalNotification: View {
    var body: some View {
        VStack(spacing:40){
            Button("Request permission"){
                
            }.buttonStyle(.glassProminent)
        }
    }
}

#Preview {
    LocalNotification()
}

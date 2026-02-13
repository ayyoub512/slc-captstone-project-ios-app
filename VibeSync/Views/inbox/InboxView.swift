//
//  InboxView.swift
//  VibeSync
//
//  Created by Ayyoub on 12/2/2026.
//

import SwiftUI

struct InboxView: View {
    var body: some View {
        Text("Inobx")
        
        List {
            Text("Yuan")
            Text("Yuan1")
            Text("Yuan2")
            Text("Yuan3")
            Text("Yuan4")
            Text("Yuan5")
            Text("Yuan6").onTapGesture {
                
            }
        }
    }
}

#Preview {
    InboxView()
}

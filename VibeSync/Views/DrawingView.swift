//
//  ContentView.swift
//  VibeSync
//
//  Created by Ayyoub on 11/2/2026.
//

import SwiftUI

struct DrawingView: View {
    @State private var toolPickerShows = true

    var body: some View {
        VStack {
            CanvasView(toolPickerShows: $toolPickerShows)
                .frame(height: 400)
                .aspectRatio(1, contentMode: .fit, )
                .border(.red)

            HStack{
                Button(
                    "\(toolPickerShows ? "Hide" : "Show") tools",
                    systemImage: "pencil.and.scribble"
                ) {
                    toolPickerShows.toggle()
                }.buttonStyle(.bordered)
                
                Spacer()
                
                Button("Send", systemImage: "paperplane.fill") {
                    
                }.labelStyle(.titleAndIcon)
                    .buttonStyle(.glassProminent)
            }.padding()
        }
    }
}

#Preview {
    DrawingView()
}

//
//  ContentView.swift
//  VibeSync
//
//  Created by Ayyoub on 11/2/2026.
//

import PencilKit
import SwiftUI

struct DrawingView: View {
    //    @State private var finalDrawingImage: DrawingImage? = nil
    @State private var canvasView: PKCanvasView?
    
    @State private var showSendMessageSheet = false
    @State private var navManager = NavigationManager()
    @State private var toolsVisible = true  // Track the manual toggle

    // Logout functionality, will later move this out of here into profile view
    @StateObject var loginViewModel = LoginViewModel()
    @EnvironmentObject var authService: AuthService

    // For permission
    @StateObject private var notificationManager = NotificationsManager()

    var body: some View {
        VStack {
            topButtons
                .padding()

            CanvasView(
                isVisible: toolsVisible && (navManager.selectedTab == 1),
//                canvasView: $canvasView,
                onCanvasReady: { canvas in
                    canvasView = canvas
                }
            )
            .frame(height: 400)
            .aspectRatio(1, contentMode: .fit, )
            .border(.gray)

            footerButtons
                .padding()

        }
        .sheet(
            isPresented: $showSendMessageSheet,
            onDismiss: {
                canvasView?.becomeFirstResponder()
            }
        ) {
            sheetView
                .presentationDetents([.medium])
        }

    }

    var topButtons: some View {
        HStack {
            Group {
                Button("Logout", systemImage: "person.crop.circle.badge.minus")
                {
                    authService.logout()
                }

                Button("Save", systemImage: "square.and.arrow.down") {
                    saveImage()
                }

                Button("Get Notified", systemImage: "message.badge") {
                    Task {
                        await notificationManager.request()
                    }
                }
                //.disabled(notificationManager.hasPermission)

            }.buttonStyle(.glass)
                .frame(alignment: .trailing)

        }.task {
            await notificationManager.getAuthStatus()
        }
    }

    var footerButtons: some View {
        HStack {

            Button("Undo", systemImage: "arrow.uturn.backward") {
                canvasView?.undoManager?.undo()
            }.buttonStyle(.glass)

            // New Toggle Button
            Button(
                toolsVisible ? "Hide Tools" : "Show Tools",
                systemImage: toolsVisible
                    ? "pencil.tip.crop.circle.badge.minus"
                    : "pencil.tip.crop.circle.badge.plus"
            ) {
                toolsVisible.toggle()
            }
            .buttonStyle(.glass)

            Spacer()

            Button("Send", systemImage: "paperplane.fill") {
//                canvasView?.resignFirstResponder()
                showSendMessageSheet = true
            }.labelStyle(.titleAndIcon)
                .buttonStyle(.glassProminent)
        }

    }

    var sheetView: some View {
        VStack {
            Text("Send a message to user #12")
                .font(.headline)
                .padding()

            Button("Send Test Notification") {
//                notificationManager.sendTestNotification(to: 12)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }

    func saveImage() {
        // I need to make the background white, otherwise it will save drawing with black bg
        guard let canvasView = canvasView else{
            print("")
            return
        }
        let renderer = UIGraphicsImageRenderer(bounds: canvasView.bounds)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(canvasView.bounds)

            // Render the canvasView layer (includes all strokes)
            canvasView.layer.render(in: ctx.cgContext)
        }
        ImageSaver().writeToPhotoAlbum(image: image)
        //finalDrawingImage = DrawingImage(image: image)
    }

}

#Preview {
    DrawingView()
}

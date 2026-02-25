//
//  ContentView.swift
//  VibeSync
//
//  Created by Ayyoub on 11/2/2026.
//

import PencilKit
import SwiftUI

enum NavigationPage {
    case inboxPage
    case drawPage
}

class NavigationManager {
    static let shared = NavigationManager()
    var path = NavigationPath()

    private init() {}

}

struct DrawingView: View {
    //    @State private var finalDrawingImage: DrawingImage? = nil
    @State private var canvasView = PKCanvasView()
    @State private var showSendMessageSheet = false
    @State private var navManager = NavigationManager.shared

    // Logout functionality, will later move this out of here into profile view
    @StateObject var loginViewModel = LoginViewModel()
    @EnvironmentObject var authService: AuthService

    // For permission
    @StateObject private var notificationManager = NotificationsManager()

    var body: some View {
        VStack {
            topButtons
                .padding()

            CanvasView(canvasView: $canvasView)
                .frame(height: 400)
                .aspectRatio(1, contentMode: .fit, )
                .border(.gray)

            footerButtons
                .padding()

        }
        .sheet(
            isPresented: $showSendMessageSheet,
            onDismiss: {
                canvasView.becomeFirstResponder()
            }
        ) {
            sheetView
                .presentationDetents([.medium])
        }

    }

    var topButtons: some View {
        HStack {
            Group{
                Button("Logout", systemImage: "person.crop.circle.badge.minus") {
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
                canvasView.undoManager?.undo()
            }.buttonStyle(.glass)

            Spacer()

            Button("Send", systemImage: "paperplane.fill") {
                canvasView.resignFirstResponder()
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
                notificationManager.sendTestNotification(to: 12)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }

    func saveImage() {
        // I need to make the background white, otherwise it will save drawing with black bg
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

// Helper class for saving images
class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(saveCompleted(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }

    @objc func saveCompleted(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer?
    ) {
        if let error = error {
            print("Error saving image: \(error.localizedDescription)")
        } else {
            print("Image saved successfully!")
        }
    }
}



#Preview {
    DrawingView()
}

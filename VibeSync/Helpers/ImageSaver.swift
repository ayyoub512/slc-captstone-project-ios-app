//
//  ImageSaver.swift
//  VibeSync
//
//  Created by Ayyoub on 1/3/2026.
//

import Combine
import SwiftUI

enum SaveState {
    case idle, saving, success, failure(Error)
}

// Helper class for saving images
final class ImageSaver: NSObject, ObservableObject {
    @Published var saveState: SaveState = .idle
    
    func writeToPhotoAlbum(image: UIImage) {
        saveState = .saving
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
        DispatchQueue.main.async{
            if let error = error {
                self.saveState = .failure(error)
            } else {
                self.saveState = .success
                
                // Reset to default after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.saveState = .idle
                }
            }
        }
    }
}

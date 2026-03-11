//
//  PhotoModelFileManager.swift
//  VibeSync
//
//  Created by Ayyoub on 9/3/2026.
//

import Foundation
import SwiftUI

class PhotoModelFileManager {
    static let shared = PhotoModelFileManager()
    private let folderName = "downloaded_photos"
    private init() {
        createFolderIfNeeded()
    }

    private func createFolderIfNeeded() {
        guard let url = getFolderPath() else { return }

        if !FileManager.default.fileExists(atPath: url.path()) {
            do {
                try FileManager.default.createDirectory(
                    at: url,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                print("Created Photo Cache Folder!")
            } catch let error {
                print("Error creating photo cache folder: \(error)")
            }
        }
    }

    private func getImagePath(key: String) -> URL? {
        guard let folder = getFolderPath() else {
            return nil
        }

        return folder.appendingPathComponent(key + ".jpg")
    }

    func add(key: String, value: UIImage) {
        guard let data = value.jpegData(compressionQuality: 1),
            let url = getImagePath(key: key)
        else { return }
        
        do {
            try data.write(to: url)
        }catch let error {
            print("Error saving photo to file manager. \(error)")
        }
    }
    
    func get(key: String) -> UIImage? {
        guard let url = getImagePath(key: key),
              FileManager.default.fileExists(atPath: url.path()) else {
            return nil
        }
        
        return UIImage(contentsOfFile: url.path)
    }

    private func getFolderPath() -> URL? {
        return FileManager
            .default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(folderName)
    }
}

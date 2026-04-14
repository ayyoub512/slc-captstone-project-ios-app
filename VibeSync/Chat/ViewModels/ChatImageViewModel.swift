//
//  ChatImageViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 9/3/2026.
//

import Foundation
import SwiftUI

@Observable
class ChatImageViewModel {
    var isLoading: Bool = false
    var image: UIImage?
    let imageKey: String
    var imageUrl: String
    let cacheManager = ImageFileCacheService.shared

    init(key: String, url: String) {
        self.imageKey = key
        self.imageUrl = url

    }

    func getImage() async {
        isLoading = true
        defer {
            isLoading = false
        }
        if let savedImage = cacheManager.get(key: imageKey) {
            image = savedImage
            return
        }

        do {
            try await downloadImage()
        } catch {
            isLoading = false
            Log.shared.error("Image download failed: \(error)")
        }

    }

    func downloadImage() async throws {
        await MainActor.run {
            isLoading = true
        }

        guard let url = URL(string: imageUrl) else {
            Log.shared.error("ChatImageViewModel: Cant get imageURL")
            await MainActor.run {
                isLoading = false
            }
            return
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            await MainActor.run {
                isLoading = false
            }
            throw URLError(.badServerResponse)
        }

        guard let downloadImage = UIImage(data: data) else {
            await MainActor.run {
                isLoading = false
            }
            throw URLError(.cannotDecodeContentData)
        }

        Log.shared.debug("Caching downloaded image \(imageUrl)")
        self.cacheManager.add(key: self.imageKey, value: downloadImage)

        await MainActor.run {
            self.isLoading = false
            self.image = downloadImage
        }
    }

}

//
//  VibeImageFullScreenViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 15/4/2026.
//

import Combine
import SwiftUI

@Observable
class VibeImageFullScreenViewModel {
    private let imageSaver = ImageSaver()
    private var cancellables = Set<AnyCancellable>()

    var saveState: SaveState = .idle
    let imageURL: String
    var image: UIImage? = nil

    
    init(imageURL: String) {
        self.imageURL = imageURL

        // observe ImageSaver
        imageSaver.$saveState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.saveState = state
            }
            .store(in: &cancellables)
        Task {
            await loadUIImage()
        }
    }

    func saveImage() {
        guard let img = image else {
            return
        }
        self.imageSaver.writeToPhotoAlbum(image: img)
    }

    func loadUIImage() async {
        guard let url = URL(string: imageURL) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            self.image = UIImage(data: data)
        } catch {
            Log.shared.error(
                "VibeImageFullScreenViewModel - LoadUIImage: \(error)"
            )
        }
    }
}

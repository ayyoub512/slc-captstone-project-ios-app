//
//  ChatImageViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 9/3/2026.
//

import Foundation
import SwiftUI

@Observable
class ChatImageViewModel{
    var isLoading: Bool = false
    var image: UIImage?
    let imageKey: String
    var imageUrl: String
    let cacheManager = PhotoModelFileManager.shared
    
    init(key: String, url: String){
        self.imageKey = key
        self.imageUrl = url
        
    }
    
    func getImage() async{
        if let savedImage = cacheManager.get(key: imageKey) {
            await MainActor.run{
                image = savedImage
            }
            Log.shared.debug("Getting Cached Image")
            return
        }
        do{
            try await downloadImage()
            print("Downloading image now!")
        }catch{
            await MainActor.run{
                isLoading = false
            }
            Log.shared.error("Image download failed: \(error)")
        }
        
    }
    
    func downloadImage() async throws{
        Log.shared.debug("inside downloadImage()")
        await MainActor.run{
            isLoading = true
        }
     
        guard let url = URL(string: imageUrl) else{
            Log.shared.error("ChatImageViewModel: Cant get imageURL")
            await MainActor.run{
                isLoading = false
            }
            return
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            await MainActor.run{
                isLoading = false
            }
            throw URLError(.badServerResponse)
        }
        
        guard let downloadImage = UIImage(data: data) else {
            await MainActor.run{
                isLoading = false
            }
            throw URLError(.cannotDecodeContentData)
        }

//        Task.detached(priority: .background) {
        Log.shared.debug("Caching downloaded image \(imageUrl)")
        self.cacheManager.add(key: self.imageKey, value: downloadImage)
//        }
        
        await MainActor.run{
            self.isLoading = false
            self.image = downloadImage
        }
    }
    
}

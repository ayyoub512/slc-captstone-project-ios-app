//
//  MessageViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 25/2/2026.
//

import Combine
import Foundation

@Observable
class ChatViewModel {

    var messages: [VibeMessage] = []
    var isLoading = false
    var errorMessage: String?
    
    var allMessagesCount: Int {
        allMessage.count
    }
    
    private var allMessage: [VibeMessage] = []
    private let pageSize = 6
    private var currentIndex = 0

    let token: String = {
        return KeyChainManager.shared.get(key: K.shared.keyChainUserTokenKey)
    }()

    func appendNextPageMessages() {
        guard currentIndex < allMessage.count else { return }
    
        let nextIndex = min(currentIndex + pageSize, allMessage.count)
        let slice = Array(allMessage[currentIndex..<nextIndex].reversed())

        messages.insert(contentsOf: slice, at: 0)
        currentIndex = nextIndex
    }

    func fetchMessages(friendID: String) async {
        guard let url = URL(string: K.shared.getMessagesURL) else {
            self.errorMessage = "Invalide URL configuration"
            return
        }

        isLoading = true
        errorMessage = nil

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(
            "Bearer \(self.token)",
            forHTTPHeaderField: "Authorization"
        )

        let body: [String: String] = ["friendID": friendID]
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            // 1. Check HTTP Status
            if let httpResponse = response as? HTTPURLResponse,
                !(200...299).contains(httpResponse.statusCode)
            {
                print("Error \(httpResponse)")
                self.errorMessage = "Server Error: \(httpResponse.statusCode)"
                isLoading = false
                return
            }

            // 2. Decode JSON
            let decoded = try JSONDecoder().decode(
                MessageResponse.self,
                from: data
            )

            self.allMessage = decoded.messages
            self.appendNextPageMessages()
            
            Log.shared.debug("\(decoded.messages.count)")
            Log.shared.debug("\(decoded.messages)")

        } catch let decodingError as DecodingError {
            print("Decoding Error: \(decodingError)")
            self.errorMessage = "Data format error from server."
        } catch {
            print("Network Error: \(error)")
            self.errorMessage = "Check your internet connection."
        }

        isLoading = false
    }

    
    func haLoadedFirstPage() -> Bool {
        return messages.count == pageSize
    }
}

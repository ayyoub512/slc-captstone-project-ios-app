//
//  AddFriendViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 11/3/2026.
//
import Combine
import SwiftData
import SwiftUI

class AddFriendViewModel: ObservableObject {
    
    @Published var working = false
    @Published var errorMessage: String?
    @Published var success: Bool?
    
    let token: String = {
        return KeyChainManager.shared.get(key: K.shared.keyChainUserTokenKey)
    }()
    
    
    func addFriend(with inviteCode: String) async {
        guard let addFriendsURL = URL(string: K.shared.addFriendURL) else {
            Log.shared.info(
                "addFriend(with inviteCode error: K.shared.addFriendURL is not found"
            )
            self.working = false
            self.success = false
            self.errorMessage = "Error adding friend, please try again later!"
            return
        }
        
        self.working = true
        self.errorMessage = nil
        self.success = nil
        
        do {
            // Setting up the request
            var request = URLRequest(url: addFriendsURL)
            request.httpMethod = "POST"
            request.addValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.addValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
            
            let body: [String: Any] = [
                "inviteCode": inviteCode
            ]
            
            request.httpBody = try? JSONSerialization.data(
                withJSONObject: body,
                options: []
            )
            
            // Using await to perform the request
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            
            // Checking errors (e.g,  401)
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode)
            {
                Log.shared.error("Server error: \(httpResponse.statusCode)")
                self.errorMessage = "Server error: \(httpResponse.statusCode)"
                self.working = false
                self.success = false
                return
            }
            
            // Decoding
            let decodedResponse = try JSONDecoder().decode(
                AddFriendResponse.self,
                from: data
            )
            
            //Updating UI
            self.working = false
            if decodedResponse.success ?? false {
                self.errorMessage = nil
                self.success = true
            } else {
                self.errorMessage = decodedResponse.message
                self.success = false
            }
            
        } catch {
            Log.shared.error("Fetch Friends error: \(error)")
            self.errorMessage =
            "Failed to add friend: \(error.localizedDescription)"
            self.success = false
            self.working = false
        }
        
        working = false
    }
    
    
}

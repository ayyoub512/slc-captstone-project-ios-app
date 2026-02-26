//
//  InboxViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 25/2/2026.
//

import Foundation
import Combine


@MainActor
class InboxViewModel: ObservableObject {
    
    @Published var friends: [Friend] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    
    func fetchFriends(token: String) async {
        guard let friendsListURL = URL(string: K.shared.friendsListURL) else {
            self.errorMessage = "Invalide URL configuration"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Setting up the request
            var request = URLRequest(url: friendsListURL)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            // Using await to perform the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Checking errors (e.g,  401)
            if let httpResponse  = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                self.errorMessage = "Server error: \(httpResponse.statusCode)"
                isLoading = false
                return
            }
            
            // Decoding
            let decodedResponse = try JSONDecoder().decode(FriendListResponse.self, from: data)
            
            //Updating UI
            self.friends = decodedResponse.friends
        }catch {
            print("Fetch Friends error: \(error)")
            self.errorMessage = "Failed to load friends"
        }
        
        isLoading = false
    }
    
    
//    func fetchFriends(token: String){
//        guard let friendsListURL = URL(string: K.shared.friendsListURL) else {return}
//        
//        var request = URLRequest(url: friendsListURL)
//        request.httpMethod = "GET"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        
//        isLoading = true
//        errorMessage = nil
//        
//        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//            DispatchQueue.main.async{
//                self?.isLoading = false
//                if let error = error {
//                    self?.errorMessage = error.localizedDescription
//                    return
//                }
//                
//                guard let data = data else {
//                    self?.errorMessage = "No data received"
//                    return
//                }
//                
//                do {
//                    let decodedResponse = try JSONDecoder().decode(FriendListResponse.self, from: data)
//                    self?.friends = decodedResponse.friends
//                }catch {
//                    print("Dcoding fetchFriends error: \(error)")
//                    self?.errorMessage = "Failed to load friends"
//                }
//            }
//        }.resume()
//    }
    
}



struct Friend: Codable, Identifiable, Hashable {
    var id: String { _id } // Map MongoDB _id to SwiftUI id
    let _id: String
    let name: String
    let email: String
}

struct FriendListResponse: Codable {
    let message: String
    let friends: [Friend]
}

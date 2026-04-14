//
//  ProfileViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 13/4/2026.
//

import Foundation

@Observable
class ProfileViewModel {
    var isDeleting = false
    var errorMessage: String?
    var showDeleteConfirmation = false
    
    func deleteAccount() async -> Bool {
        isDeleting = true
        errorMessage = nil
        
        let token = KeyChainManager.shared.get(key: K.shared.keyChainUserTokenKey)
        
        guard !token.isEmpty,
              let url = URL(string: K.shared.deleteUserDataURL)
        else {
            errorMessage = "Something went wrong, please logout and try again"
            isDeleting = false
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                errorMessage = "Failed to delete account"
                isDeleting = false
                return false
            }
            isDeleting = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isDeleting = false
            return false
        }
    }
}

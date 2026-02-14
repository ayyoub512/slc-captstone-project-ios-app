//
//  AuthService.swift
//  VibeSync
//
//  Created by Ayyoub on 13/2/2026.
//  - https://www.youtube.com/watch?v=GUayNp1qn9U

import Combine
import Foundation
import KeychainSwift

enum AuthenticationError: Error {
    case invalideCredentials
    case custom(errorMessage: String)
}

struct LoginRequestBody: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String?
    let message: String?
    let success: Bool?
}

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    private let keyChain = KeychainSwift()
    private let userTokenkey = "userToken"
    private let api_uri = "http://localhost:5001/api"
    
    init() {
       loadToken()
    }
    
    func loadToken(){
        updateAuthStatus(isAuthenticated: keyChain.get(userTokenkey) != nil)
    }
    
    func updateAuthStatus(isAuthenticated: Bool) {
        DispatchQueue.main.async {
            self.isAuthenticated = isAuthenticated
        }
    }
    
    func saveToken(_ token: String) {
        keyChain.set(token, forKey: userTokenkey)
        keyChain.synchronizable = true
        self.updateAuthStatus(isAuthenticated: true)
    }
    
    func logout() {
        keyChain.delete(userTokenkey)
        self.updateAuthStatus(isAuthenticated: false)
    }

    
    // Login function
    func login(
        username: String,
        password: String,
        completion: @escaping (Result<String, AuthenticationError>) -> Void
    ) {
        guard let url = URL(string: "\(api_uri)/auth/login")
        else {
            completion(.failure(.custom(errorMessage: "Invalid URL")))
            return
        }

        let body = LoginRequestBody(email: username, password: password)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else{
                completion(.failure(.custom(errorMessage: "No data")))
                return
            }
            
            guard let loginResponse = try? JSONDecoder().decode(LoginResponse.self,  from: data) else{
                completion(.failure(.invalideCredentials))
                return
            }
            
            guard let token = loginResponse.token else {
                completion(.failure(.invalideCredentials))
                return
            }
            
            self.saveToken(token)
            
            completion(.success(token))
        }.resume()
    }
}

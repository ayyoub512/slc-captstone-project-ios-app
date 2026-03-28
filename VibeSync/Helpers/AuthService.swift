//
//  AuthService.swift
//  VibeSync
//
//  Created by Ayyoub on 13/2/2026.
//  - https://www.youtube.com/watch?v=GUayNp1qn9U

import Combine
import Foundation
import KeychainSwift

@Observable
class AuthService {
    static let shared = AuthService()
    
    private let kcManager = KeyChainManager.shared
    
    var isAuthenticated = false
    
    private init() {
        checkAuthStatus()
    }

    func checkAuthStatus() {
        let token = kcManager.get(key: K.shared.keyChainUserTokenKey)
        self.isAuthenticated = token.isEmpty ? false: true
    }

    func updateAuthStatus(isAuthenticated: Bool) {
        DispatchQueue.main.async {
            self.isAuthenticated = isAuthenticated
        }
    }

    func logout() {
        kcManager.clearKeyChain()
        self.updateAuthStatus(isAuthenticated: false)
    }
}


// TODO: This should not be in auth
extension AuthService {
    func login(
        email: String,
        password: String,
        completion: @escaping authCompletionHandlerAlias
    ) {
        guard let url = URL(string: K.shared.logingURL)
        else {
            completion(.failure(.custom(errorMessage: "Invalid URL")))
            return
        }

        let body = LoginRequestBody(email: email, password: password)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(.custom(errorMessage: "No data")))
                return
            }

            guard
                let loginResponse = try? JSONDecoder().decode(
                    LoginResponse.self,
                    from: data
                )
            else {
                completion(.failure(.invalideCredentials))
                return
            }

            guard let token = loginResponse.token else {
                completion(.failure(.invalideCredentials))
                return
            }
            self.kcManager.save(key: K.shared.keyChainUserTokenKey, value: token)

            guard let inviteCode = loginResponse.inviteCode else {
                completion(.failure(.invalideCredentials))
                return
            }
            self.kcManager.save(
                key: K.shared.keychainInviteCodeKey,
                value: inviteCode
            )
            
            guard let userID = loginResponse.userID else {
                completion(.failure(.invalideCredentials))
                return
            }
            self.kcManager.save(
                key: K.shared.keychainUserIDKey,
                value: userID
            )

            completion(.success(token))
        }.resume()
    }
  
    func register(
        name: String,
        email: String,
        password: String,
        completion: @escaping authCompletionHandlerAlias
    ) {
        guard let url = URL(string: (K.shared.registerURL))
        else {
            completion(.failure(.custom(errorMessage: "Invalid URL")))
            return
        }

        let body = User(email: email, password: password, name: name)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(.failure(.custom(errorMessage: "No data")))
                return
            }

            guard
                let registerResponse = try? JSONDecoder().decode(
                    RegisterResponse.self,
                    from: data
                )
            else {
                completion(.failure(.invalideCredentials))
                return
            }

            guard let token = registerResponse.token else {
                completion(.failure(.invalideCredentials))
                return
            }

            self.kcManager.save(key: K.shared.keyChainUserTokenKey, value: token)

            guard let inviteCode = registerResponse.inviteCode else {
                completion(.failure(.invalideCredentials))
                return
            }
            self.kcManager.save(
                key: K.shared.keychainInviteCodeKey,
                value: inviteCode
            )
            
            guard let userID = registerResponse.userID else {
                completion(.failure(.invalideCredentials))
                return
            }
            self.kcManager.save(
                key: K.shared.keychainUserIDKey,
                value: userID
            )

            completion(.success(token))
        }.resume()
    }

}


typealias authCompletionHandlerAlias = (Result<String, AuthenticationError>) ->
    Void

enum AuthenticationError: Error {
    case invalideCredentials
    case custom(errorMessage: String)
}

struct LoginRequestBody: Codable {
    let email: String
    let password: String
}

struct User: Codable {
    let email: String
    let password: String
    let name: String?  // optional since this will be used for login/register
}

struct RegisterResponse: Codable {
    let token: String?
    let message: String?
    let error: String?
    let inviteCode: String?
    let userID: String?
}

struct LoginResponse: Codable {
    let token: String?
    let message: String?
    let error: String?
    let inviteCode: String?
    let userID: String?
}

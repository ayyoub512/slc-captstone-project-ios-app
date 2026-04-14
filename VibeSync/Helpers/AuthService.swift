//
//  AuthService.swift
//  VibeSync
//
//  Created by Ayyoub on 13/2/2026.
//  - https://www.youtube.com/watch?v=GUayNp1qn9U

import AuthenticationServices
import Combine
import Foundation
import KeychainSwift
import SwiftData
import SwiftUI

@Observable
class AuthService {
    static let shared = AuthService()

    private let kcManager = KeyChainManager.shared
    private let installManager = AppReinstallManager.shared

    var isAuthenticated = false
    var signInError: String?

    private init() {
        // Clear keychain if the app was installed so it doesnt auto logging
        installManager.handleFreshInstall()

        checkAuthStatus()
    }

    func checkAuthStatus() {
        let token = kcManager.get(key: K.shared.keyChainUserTokenKey)
        self.isAuthenticated = token.isEmpty ? false : true
    }

    func updateAuthStatus(isAuthenticated: Bool) {
        DispatchQueue.main.async {
            self.isAuthenticated = isAuthenticated
        }
    }

    func logout(modelContext: ModelContext) {
        Log.shared.debug("Logging out.")
        self.clearCachedData(modelContext: modelContext)
        self.updateAuthStatus(isAuthenticated: false)
    }

    func clearCachedData(modelContext: ModelContext) {
        Log.shared.debug("Removing all cached data.")
        // Clearing key chain
        kcManager.clearKeyChain()
        // Clear all cached data: friends list & image
        do {
            try modelContext.delete(model: FriendModel.self)
            Log.shared.info("Deteted cached friends")
        } catch {
            Log.shared.error("Failed to clear FriendModel: \(error)")
        }
    }

    // Sign in with apple
    func checkCredentialStatus(modelContext: ModelContext) {
        var userId: String = kcManager.get(key: K.shared.keychainAppleUserId)

        if userId.isEmpty {
            Log.shared.error("User ID not found. not signed in with Apple")
            kcManager.clearKeyChain()
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userId) { state, error in
            DispatchQueue.main.async {
                switch state {
                case .authorized:
                    Log.shared.info("User is authorized")

                case .revoked:
                    Log.shared.error("User revoked access")
                    userId = ""
                    self.logout(modelContext: modelContext)  // I am not sure if its right to do this.

                case .notFound:
                    Log.shared.error(
                        "User has never logged in with Apple on this device"
                    )
                    self.logout(modelContext: modelContext)

                case .transferred:
                    Log.shared.error("Credential transferred")
                    self.logout(modelContext: modelContext)

                @unknown default:
                    self.logout(modelContext: modelContext)

                }
            }
        }

    }
}

// TODO: This should not be in auth
extension AuthService {
    // Replaces the old sign in with email / password
    func signInWithApple(
        token: String,
        userID: String,
        email: String?,
        name: String?
    ) async {
        guard let url = URL(string: K.shared.signInWithAppleURL) else { return }

        let body = AppleSignInRequest(
            identityToken: token,
            appleUserID: userID,
            email: email,
            name: name,
            mobileApp: true
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let http = response as? HTTPURLResponse,
                (200...299).contains(http.statusCode)
            else {
                signInError = "Server error. Please try again"
                return
            }

            let decoded = try JSONDecoder().decode(
                AppleSignInResponse.self,
                from: data
            )

            guard let authToken = decoded.token else {
                signInError = "Auth token error. Please try again"
                return
            }

            KeyChainManager.shared.save(
                key: K.shared.keyChainUserTokenKey,
                value: authToken
            )

            guard let inviteCode = decoded.inviteCode else {
                signInError = "Invite code generation failed. Please try again"
                return
            }
            self.kcManager.save(
                key: K.shared.keychainInviteCodeKey,
                value: inviteCode
            )

            guard let userID = decoded.userID else {
                signInError = "User ID fetch error. Please try again"
                return
            }

            self.kcManager.save(
                key: K.shared.keychainUserIDKey,
                value: userID
            )

            if let fullName = decoded.name {
                self.kcManager.save(
                    key: K.shared.keychainApplefullName,
                    value: fullName
                )
            }

            self.updateAuthStatus(isAuthenticated: true)
            self.signInError = nil

        } catch {
            print("Apple login error:", error)
        }

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

struct AppleSignInRequest: Codable {
    let identityToken: String
    let appleUserID: String
    let email: String?
    let name: String?
    let mobileApp: Bool
}

struct AppleSignInResponse: Codable {
    let token: String?
    let message: String?
    let error: String?
    let inviteCode: String?
    let userID: String?
    let name: String?
}

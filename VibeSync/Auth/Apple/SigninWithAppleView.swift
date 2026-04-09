//
//  SigninWithAppleView.swift
//  VibeSync
//
//  Created by Ayyoub on 11/3/2026.
//

import AuthenticationServices
import SwiftUI

struct SigninWithAppleView: View {

    @State var authentication = AuthService.shared

    var body: some View {
        NavigationView {
            VStack {
                // if self.userId.isEmpty {
                SignInButtonView(authentication: authentication)

                if let err = authentication.signInError {
                    Text(err)
                        .foregroundStyle(.red)
                }

            }.navigationTitle("Sign In")
        }
    }

}

struct SignInButtonView: View {
    @State var authentication: AuthService
    @State var identityToken: String = ""

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.email, .fullName]

        } onCompletion: { result in
            switch result {
            case .success(let auth):
                handleAuthorization(auth)

            case .failure(let error):
                Log.shared.error("Error sign in with apple: \(error)")
            }
        }
        .signInWithAppleButtonStyle(
            colorScheme == .dark ? .white : .black
        )
        .frame(height: 50)
        .padding()
        .cornerRadius(8)
    }

    private func handleAuthorization(_ auth: ASAuthorization) {
        guard
            let credential = auth.credential
                as? ASAuthorizationAppleIDCredential
        else {
            Log.shared.error("Invalid Sign In With Apple Credential type")
            return
        }

        var email: String = ""
        var fullName: String = ""

        // Only the first time the user sign in
        let userID = credential.user

        // Only on first sign up
        if let credEmail = credential.email {
            email = credEmail
        }

        if let credName = credential.fullName {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .default
            fullName = formatter.string(from: credName)
        }

        Task {
            if let tokenData = credential.identityToken,
                let tokenString = String(data: tokenData, encoding: .utf8)
            {
                await self.authentication.signInWithApple(
                    token: tokenString,
                    userID: userID,
                    email: email,
                    name: fullName
                )
            } else {
                Log.shared.error("Identity token missing")
                self.authentication.signInError = "Apple identity token missing"
            }
        }

    }
}

#Preview {
    SigninWithAppleView()
}

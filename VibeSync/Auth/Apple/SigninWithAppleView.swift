//
//  SigninWithAppleView.swift
//  VibeSync
//
//  Created by Ayyoub on 11/3/2026.
//

import AuthenticationServices
import SwiftUI

struct SigninWithAppleView: View {

    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage(K.shared.appleEmail) var email: String = ""
    @AppStorage(K.shared.appleFirstName) var firstName: String = ""
    @AppStorage(K.shared.appleLastName) var lastName: String = ""
    @AppStorage(K.shared.appleUserId) var userId: String = ""
    @AppStorage(K.shared.appleIdentityToken) var identityToken: String = ""
    @AppStorage(K.shared.appleUsername) var userName: String = ""
    
    @State var authentication = AuthService.shared
    

    var body: some View {
        NavigationView {
            VStack {
                Text("email: \(email)")
                Text("firstName: \(firstName)")
                Text("lastName: \(lastName)")
                Text("userId: \(userId)")
                Text("identityToken: \(identityToken)")
                
                
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

            }.navigationTitle("Sign In")
        }
    }
    
    private func handleAuthorization(_ auth: ASAuthorization){
        guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
            Log.shared.error("Invalid Sign In With Apple Credential type")
            return
        }
        
        // Only the first time the user sign in
        let userID = credential.user

        // Only on first sign up
        let email = credential.email
        let firstName = credential.fullName?.givenName
        let lastName = credential.fullName?.familyName
        let tokenData = credential.identityToken

        self.userId = userID
        self.email = email ?? ""
        self.firstName = firstName ?? ""
        self.lastName = lastName ?? ""
        if let identityToken = tokenData,
           let token = String(data: identityToken, encoding: .utf8){
            self.identityToken = token
        }
        
        authentication.isAuthenticated = true
        
    }
}

#Preview {
    SigninWithAppleView()
}

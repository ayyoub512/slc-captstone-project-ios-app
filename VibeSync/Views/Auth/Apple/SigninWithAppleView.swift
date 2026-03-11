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
    @AppStorage("email") var email: String = ""
    @AppStorage("firstName") var firstName: String = ""
    @AppStorage("lastName") var lastName: String = ""
    @AppStorage("userId") var userId: String = ""
    @AppStorage("identityToken") var identityToken: String = ""
    

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
                        switch auth.credential {
                        case let credential as ASAuthorizationAppleIDCredential:
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
                            
                        default:
                            break
                        }
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
}

#Preview {
    SigninWithAppleView()
}

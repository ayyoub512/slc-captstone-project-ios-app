//
//  LoginView.swift
//  VibeSync
//
//  Created by Ayyoub on 13/2/2026.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var loginViewModel = LoginViewModel()
    @EnvironmentObject var authentication: AuthService

    var body: some View {
        Form {
            TextField("Enter your email", text: $loginViewModel.email)
                .autocapitalization(.none)
            SecureField("Enter your password", text: $loginViewModel.password)
                
            Button("Login") {
                loginViewModel.login(authentication: authentication)

            }
            .buttonStyle(.glassProminent)

        }
    }
}

#Preview {
    LoginView()
}

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
            TextField("Email", text: $loginViewModel.username)
                .autocapitalization(.none)
            SecureField("Password", text: $loginViewModel.password)

            HStack {
                Spacer()
                Button("Login") {
                    loginViewModel.login(authentication: authentication)

                }.buttonStyle(.glassProminent)

                Spacer()
            }
        }
    }
}

#Preview {
    LoginView()
}

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

    // Closure to switch to Register
    var onSwitchToRegister: () -> Void

    var body: some View {
        Form {
            TextField("Enter your email", text: $loginViewModel.email)
                .autocapitalization(.none)
            SecureField("Enter your password", text: $loginViewModel.password)

            Button {
                loginViewModel.login(authentication: authentication)
            }label: {
                Text("Login")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)

            Button("Don't have an account? Register") {
                onSwitchToRegister()
            }
            .font(.footnote)
            .foregroundColor(.cyan)
            .padding(.top, 8)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Sign in")
                    .font(.largeTitle.bold())
            }
        }
    }
}

#Preview {
    //    LoginView()
}

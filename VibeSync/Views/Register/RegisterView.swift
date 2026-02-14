//
//  LoginView.swift
//  VibeSync
//
//  Created by Ayyoub on 13/2/2026.
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var regiterViewModel = RegisterViewModel()
    @EnvironmentObject var authentication: AuthService

    var body: some View {
        Form {
            TextField("Name", text: $regiterViewModel.name)
                .autocapitalization(.none)
        
            TextField("Email", text: $regiterViewModel.email)
                .autocapitalization(.none)
            
            SecureField("Password", text: $regiterViewModel.password)

            HStack {
                Spacer()
                Button("Register") {
                    regiterViewModel.register(authentication: authentication)
                }.buttonStyle(.glassProminent)
                Spacer()
            }
        }
    }
}

#Preview {
    LoginView()
}

//
//  AuthContainerView.swift
//  VibeSync
//
//  Created by Ayyoub on 2/3/2026.
//
import SwiftUI

struct AuthContainerView: View {
    @State private var showLogin = true
    @EnvironmentObject var authentication: AuthService

    var body: some View {
        VStack {
            if showLogin {
                LoginView {
                    withAnimation {
                        showLogin = false
                    }
                }
                .transition(.move(edge: .trailing))
            } else {
                RegisterView {
                    withAnimation {
                        showLogin = true
                    }
                }
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut, value: showLogin)
//        .padding()
    }
}


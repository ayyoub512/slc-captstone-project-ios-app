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
    @State private var animate = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.85),
                        Color.brandPrimary.opacity(0.9),
                        Color.brandPrimary.opacity(1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Moving light layer
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.clear,
                    ],
                    center: animate ? .topTrailing : .topLeading,
                    startRadius: 50,
                    endRadius: 300
                )
                .blur(radius: 30)
                .animation(
                    .easeInOut(duration: 12)
                        .repeatForever(autoreverses: true),
                    value: animate
                )
                .onAppear {
                    animate = true
                }

                VStack(spacing: 20) {

                    Spacer()

                    // App Icon
                    Image("logoWhiteSmall")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(22)

                    Text("Vibe Sync")
                        .foregroundStyle(.white.gradient)
                        .font(.largeTitle.bold())

                    Text("Live pics from your friends,\n on your home screen")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.gradient)
                        .font(.title3.bold())

                    Spacer()

                    
                    if let err = authentication.signInError {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    SignInButtonView(authentication: authentication)
                        .padding(.bottom, 60)

                    
                }
            }
            .navigationBarHidden(true)
        }
    }

}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r: UInt64
        let g: UInt64
        let b: UInt64
        (r, g, b) = ((int >> 16) & 255, (int >> 8) & 255, int & 255)

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
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
        .signInWithAppleButtonStyle(.white)
        .frame(height: 50)
        .padding()
        .cornerRadius(8)
    }

    
    // TODO: Move this to a ViewModel
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

        let userID = credential.user
        // SAVING USER ID WHICH WILL BE COMPARED TO CHECK IF USER IS LOGGED WITH APPLE LATER
        KeyChainManager.shared.save(
            key: K.shared.keychainAppleUserId,
            value: userID
        )

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

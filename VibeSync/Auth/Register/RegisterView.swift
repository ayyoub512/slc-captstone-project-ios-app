////
////  LoginView.swift
////  VibeSync
////
////  Created by Ayyoub on 13/2/2026.
////
//
//import SwiftUI
//
//struct RegisterView: View {
//    @StateObject private var regiterViewModel = RegisterViewModel()
////    @EnvironmentObject var authentication: AuthService
//    @State var authentication = AuthService.shared
//    var onSwitchToLogin: () -> Void
//
//    var body: some View {
//        Form {
//            TextField("Name", text: $regiterViewModel.name)
//                .autocapitalization(.none)
//
//            TextField("Email", text: $regiterViewModel.email)
//                .autocapitalization(.none)
//
//            SecureField("Password", text: $regiterViewModel.password)
//
//            Button{
//                regiterViewModel.register(authentication: authentication)
//            } label: {
//                Text("Register")
//                    .frame(maxWidth: .infinity)
//            }
//            
//            .buttonStyle(.glassProminent)
//
//            Button("Already have an account? Login") {
//                onSwitchToLogin()
//            }
//            .font(.footnote)
//            .foregroundColor(.cyan)
//            .padding(.top, 8)
//        }
//        .toolbar {
//
//            ToolbarItem(placement: .principal) {
//                Text("Sign up")
//                    .font(.largeTitle.bold())
//            }
//        }
//    }
//}
//
//#Preview {
//    //    LoginView()
//}

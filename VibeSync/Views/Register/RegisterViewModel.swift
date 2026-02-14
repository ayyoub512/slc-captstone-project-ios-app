//
//  LoginViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 13/2/2026.
//

import Combine
import Foundation
import KeychainSwift

class RegisterViewModel: ObservableObject {
    var name: String = "Ayyoub Ouakkaha"
    var email: String = "hi@ayyoub.io"
    var password: String = "123"

    func register(authentication: AuthService) {
        AuthService().register(name: name, email: email, password: password){ result in
            switch result {
            case .success:
                authentication.updateAuthStatus(isAuthenticated: true)

            case .failure(let error):
                print("Error register: \(error.localizedDescription)")
            }
        }
    }
}

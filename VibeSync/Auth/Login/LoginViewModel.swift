//
//  LoginViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 13/2/2026.
//

import Foundation
import Combine
import KeychainSwift

class LoginViewModel: ObservableObject {
    var email: String = ""
    var password: String = ""
    
    func login(auth: AuthService){
        AuthService.shared.login(email: email, password: password) { result in
            switch result{
            case .success:
                auth.updateAuthStatus(isAuthenticated: true)
                
            case .failure(let error):
                print("Error login \(error.localizedDescription)")
            }
        }
    }

}

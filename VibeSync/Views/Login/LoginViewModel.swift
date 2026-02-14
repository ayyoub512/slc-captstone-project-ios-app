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
    var email: String = "hi@ayyoub.io"
    var password: String = "123"
    
    func login(authentication: AuthService){
        AuthService().login(email: email, password: password) { result in
            switch result{
            case .success:
                authentication.updateAuthStatus(isAuthenticated: true)
                
            case .failure(let error):
                print("Error login \(error.localizedDescription)")
            }
        }
    }

}

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
    var username: String = ""
    var password: String = ""
    
    func login(authentication: AuthService){
        AuthService().login(username: username, password: password) { result in
            switch result{
            case .success:
                authentication.updateAuthStatus(isAuthenticated: true)
                
            case .failure(let error):
                print("Error login \(error.localizedDescription)")
            }
        }
    }
    
    func logout(authentication: AuthService){
        authentication.logout()
    }
}

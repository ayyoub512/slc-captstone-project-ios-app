//
//  LoginViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 13/2/2026.
//

import Foundation
import Combine

class LoginViewModel: ObservableObject {
    var username: String = ""
    var password: String = ""
    
    func login(authentication: AuthService){
        AuthService().login(username: username, password: password) { result in
            switch result{
            case .success(let token):
                authentication.updateStatus(success: true)
                
            case .failure(let error):
                print("Error login \(error.localizedDescription)")
            }
        }
    }
}

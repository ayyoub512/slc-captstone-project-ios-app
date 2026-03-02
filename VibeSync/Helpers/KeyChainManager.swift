//
//  KeyChainManager.swift
//  VibeSync
//
//  Created by Ayyoub on 2/3/2026.
//

import Foundation
import KeychainSwift
import Combine

struct KeyChainManager {
    static let shared = KeyChainManager()
    
    private let keyChain: KeychainSwift = {
        let kc = KeychainSwift()
        kc.accessGroup = K.shared.keyChainSharedAccessGroup
        return kc
    }()
    
    
    func get(key: String) -> String {
        return keyChain.get(key) ?? ""
    }
    
    func saveToKeyChain(
        key: String,
        value: String,
        synchronizable: Bool = false
    ) {
        keyChain.set(value, forKey: key)
        keyChain.synchronizable = synchronizable
    }
}

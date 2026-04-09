//
//  AppReinstallHandler.swift
//  VibeSync
//
//  Created by Ayyoub on 9/4/2026.
//
// Takes care of detecting re-installs.

import Foundation

final class AppReinstallManager {

    static let shared = AppReinstallManager()
    private let keychain = KeyChainManager.shared
    
    /// Keychain key to track install version
    private let installVersionKey = "com.vibesync.installVersion"
    
    /// UserDefaults key to track first launch
    private let userDefaultsFirstLaunchKey = "com.vibesync.hasLaunchedBefore"

    private init() {}
    
    /// Detect fresh install and clear stale keychain
    func handleFreshInstall() {
        let defaults = UserDefaults.standard
        let isFirstLaunch = !defaults.bool(forKey: userDefaultsFirstLaunchKey)
        
        if isFirstLaunch {
            // App is freshly installed (or UserDefaults was cleared)
            clearStaleKeychainIfNeeded()
            
            // Mark that app has launched at least once
            defaults.set(true, forKey: userDefaultsFirstLaunchKey)
        }
    }
    
    /// Checks keychain version and clears it if it does not match current install
    private func clearStaleKeychainIfNeeded() {
        // Generate a unique version for this install
        let currentInstallVersion = UUID().uuidString
        
        // Retrieve saved version from keychain
        let savedVersion = keychain.get(key: installVersionKey)
        
        keychain.clearKeyChain()
        
        keychain.save(key: installVersionKey, value: currentInstallVersion)
    }
    
    /// Optional: manually reset keychain (for logout)
    func resetKeychain() {
        keychain.clearKeyChain()
    }
}

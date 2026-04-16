//
//  KeyboardManager.swift
//  VibeSync
//
//  Created by Ayyoub on 16/4/2026.
//
// I mainly added this file because the invite code text field in profile view wouldnt close on it won
// and remained open even clicked away or pages swipe

import Foundation
import Combine
import UIKit

@MainActor
final class KeyboardManager: ObservableObject {
    @Published var isKeyboardActive: Bool = false

    func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
        isKeyboardActive = false
    }
}

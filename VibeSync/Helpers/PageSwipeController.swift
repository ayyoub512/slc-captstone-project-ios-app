//
//  PageSwipeController.swift
//  VibeSync
//
//  Created by Ayyoub on 13/4/2026.
//

import SwiftUI

struct PageSwipeController: UIViewControllerRepresentable {
    var isEnabled: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Find the UIScrollView inside TabView's page controller and toggle it
        DispatchQueue.main.async {
            guard let window = uiViewController.view.window else { return }
            findScrollViews(in: window).forEach { $0.isScrollEnabled = isEnabled }
        }
    }

    private func findScrollViews(in view: UIView) -> [UIScrollView] {
        var result: [UIScrollView] = []
        for subview in view.subviews {
            if let scrollView = subview as? UIScrollView {
                result.append(scrollView)
            }
            result.append(contentsOf: findScrollViews(in: subview))
        }
        return result
    }
}

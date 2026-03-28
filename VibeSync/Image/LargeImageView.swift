//
//  LargeImageView.swift
//  VibeSync
//
//  Created by Ayyoub on 12/3/2026.
//

import SwiftUI

struct LargeImageView: View {
   
    @State private var path = NavigationPath()
 
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 20) {
                Text("Stack Depth: \(path.count)")
                    .font(.headline)
 
                Group {
                    Button("Push String") {
                        path.append("Hello")
                    }
 
                    Button("Push Int") {
                        path.append(42)
                    }
 
                    Button("Push Multiple") {
                        path.append("First")
                        path.append("Second")
                        path.append("Third")
                    }
                }
 
                Group {
                    Button("Pop Last") {
                        if !path.isEmpty {
                            path.removeLast()
                        }
                    }
 
                    Button("Pop All (to Root)") {
                        path.removeLast(path.count)
                    }
                }
            }
            .navigationTitle("Path Basics")
            .navigationDestination(for: String.self) { value in
                StringDetailView(value: value, path: $path)
            }
            .navigationDestination(for: Int.self) { value in
//                IntDetailView(value: value, path: $path)
            }
        }
    }
}
 
struct StringDetailView: View {
    let value: String
    @Binding var path: NavigationPath
 
    var body: some View {
        VStack {
            Text("String: \(value)")
            Text("Stack Depth: \(path.count)")
 
            Button("Pop to Root") {
                path.removeLast(path.count)
            }
        }
        .navigationTitle(value)
    }
}



#Preview {
    LargeImageView()
}

//
//  AddFriendView.swift
//  VibeSync
//
//  Created by Ayyoub on 2/3/2026.
//

import SwiftUI
import UIKit

struct AddFriendView: View {
    @State private var code: String = ""

    var body: some View {
        Form{
            Section(header: Text("Enter Friend’s Invite Code").font(.headline)) {
                TextField("Enter invite code", text: $code)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 0) // Form handles padding
               
                Button(action: {
                    submitCode()
                }) {
                    Text("Add")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
            
            Section(header: Text("Share Your Invite Code").font(.headline), footer: Text("Send this code to a friend to add you")) {
                VStack(alignment: .leading){
                    HStack{
                        Text("Your invite code is: ")
                        Spacer()
                        CopyableText(text: "G3CM2A")
                    }
                    

                }
            }

        }
    }
    
    private func submitCode() {
            print("Submitted code: \(code)")
            // Add your verification or API call here
        }
}

struct CopyableText: View {
    let text: String
    
    @State private var didCopy = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text(text)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
            
            Image(systemName: didCopy ? "checkmark.circle.fill" : "doc.on.doc")
                .font(.body)
                .foregroundStyle(didCopy ? .green : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .opacity(0.1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14)) // makes full area tappable
        .onTapGesture {
            copyToClipboard()
        }
        .animation(.easeInOut(duration: 0.2), value: didCopy)
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = text
        
        didCopy = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            didCopy = false
        }
    }
}

#Preview {
    AddFriendView()
}

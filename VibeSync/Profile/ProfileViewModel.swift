//
//  ProfileViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 13/4/2026.
//

import CryptoKit
import Foundation
import SwiftUI

@Observable
class ProfileViewModel {
    var isDeleting = false
    var errorMessage: String?
    var showDeleteConfirmation = false
    var syncState: LoadingState = .idle

    var name: String?
    var profileImage: UIImage?
    private let fileName = K.shared.profileCachedImageFileName

    private let kc = KeyChainManager.shared

    private var lastSyncedName: String?
    private var lastSyncedImageHash: String?
    private var syncTask: Task<Void, Never>?

    func loadCachedProfile() {
        let cachedName = UserDefaults.standard.string(
            forKey: K.shared.cachedUserName
        )
        self.name = cachedName

        let url = profileImageURL()
        if FileManager.default.fileExists(atPath: url.path),
            let data = try? Data(contentsOf: url),
            let image = UIImage(data: data)
        {
            self.profileImage = image
        }
    }

    func fetchProfileFromServer() async {
        guard let url = URL(string: K.shared.getProfileURL) else { return }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let token = kc.get(key: K.shared.keyChainUserTokenKey)
            request.addValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(
                ProfileResponse.self,
                from: data
            )

            await MainActor.run {
                self.name = response.name
                UserDefaults.standard.set(
                    response.name,
                    forKey: K.shared.cachedUserName
                )
            }

            if let imageURLString = response.profileResizedImageURL,
                let imageURL = URL(string: imageURLString)
            {
                await downloadAndCacheImage(from: imageURL)
            }

        } catch {
            Log.shared.error(
                "[ERROR: ProfileViewModel - fetchProfileFromServer] : \(error)"
            )
        }
    }

    func downloadAndCacheImage(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return }
            try saveToDisk(image: image)
            await MainActor.run { self.profileImage = image }
        } catch {
            Log.shared.error(
                "[ERROR: ProfileViewModel - downloadAndCacheImage] : \(error)"
            )
        }
    }

    func saveToDisk(image: UIImage) throws {
        let url = profileImageURL()
        let data = image.jpegData(compressionQuality: 0.8)
        try data?.write(to: url, options: .atomic)
    }

    func profileImageURL() -> URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    func deleteAccount() async -> Bool {
        isDeleting = true
        errorMessage = nil

        let token = KeyChainManager.shared.get(
            key: K.shared.keyChainUserTokenKey
        )

        guard !token.isEmpty,
            let url = URL(string: K.shared.deleteUserDataURL)
        else {
            errorMessage = "Something went wrong, please logout and try again"
            isDeleting = false
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                http.statusCode == 200
            else {
                errorMessage = "Failed to delete account"
                isDeleting = false
                return false
            }
            isDeleting = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isDeleting = false
            return false
        }
    }

    // MARK: - Profile Update

    func updateName(_ newName: String) {
        name = newName
        UserDefaults.standard.set(newName, forKey: K.shared.cachedUserName)
        scheduleSyncIfNeeded()
    }

    func updateImage(_ newImage: UIImage?) {
        profileImage = newImage
        if let image = newImage { try? saveToDisk(image: image) }
        scheduleSyncIfNeeded()
    }

    private func scheduleSyncIfNeeded() {
        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await syncIfNeeded()
        }
    }

    
    func syncIfNeeded() async {
        let currentName = name
        let currentImageHash = imageHash(profileImage)
        let currentImage = profileImage

        let hasNameChanged = currentName != lastSyncedName
        let hasImageChanged = currentImageHash != lastSyncedImageHash

        if !hasNameChanged && !hasImageChanged { return }

        syncState = .loading

        guard let url = URL(string: K.shared.updateProfileURL) else { return }

        // Capture everything needed off-actor BEFORE detaching
        let token = kc.get(key: K.shared.keyChainUserTokenKey)
        let fileName = K.shared.profileCachedImageFileName

        let result = await Task.detached(priority: .userInitiated) {
            func toData(_ string: String) -> Data {
                string.data(using: .utf8) ?? Data()
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let boundary = UUID().uuidString
            request.setValue(
                "multipart/form-data; boundary=\(boundary)",
                forHTTPHeaderField: "Content-Type"
            )

            var body = Data()

            if let name = currentName, hasNameChanged {
                body.append(contentsOf: toData("--\(boundary)\r\n"))
                body.append(contentsOf: toData("Content-Disposition: form-data; name=\"name\"\r\n\r\n"))
                body.append(contentsOf: toData("\(name)\r\n"))
            }

            if let image = currentImage,
               hasImageChanged,
               let data = image.resizedToFit(maxDimension: 1024).jpegData(compressionQuality: 0.8)
            {
                body.append(contentsOf: toData("--\(boundary)\r\n"))
                body.append(contentsOf: toData("Content-Disposition: form-data; name=\"image\"; filename=\"\(fileName)\"\r\n"))
                body.append(contentsOf: toData("Content-Type: image/jpeg\r\n\r\n"))
                body.append(data)
                body.append(contentsOf: toData("\r\n"))
            }

            body.append(contentsOf: toData("--\(boundary)--\r\n"))
            request.httpBody = body

            return try await URLSession.shared.data(for: request)
        }.result

        // Back on main actor — safe to update state
        switch result {
        case .success(let (_, response)):
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                syncState = .error("Failed to save changes")
                resetSyncStateAfterDelay()
                return
            }
            lastSyncedName = currentName
            lastSyncedImageHash = currentImageHash
            syncState = .success
            resetSyncStateAfterDelay()

        case .failure(let error):
            Log.shared.error("[ERROR: ProfileViewModel - syncIfNeeded] : \(error)")
            syncState = .error(error.localizedDescription)
            resetSyncStateAfterDelay()
        }
    }

    private func resetSyncStateAfterDelay() {
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { self.syncState = .idle }
        }
    }

    private func imageHash(_ image: UIImage?) -> String? {
        guard let data = image?.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }
            .joined()
    }
}

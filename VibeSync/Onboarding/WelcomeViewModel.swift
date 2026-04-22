//
//  WelcomeViewModel.swift
//  VibeSync
//
//  Created by Ayyoub on 17/4/2026.
//

import SwiftUI

enum LoadingState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}

@Observable
class WelcomeViewModel {
    private let kc = KeyChainManager.shared

    var state: LoadingState = .idle

    func completeOnboarding() async {
        let name = UserDefaults.standard.string(
            forKey: K.shared.onboardingProfileName
        )

        let imageURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(K.shared.profileCachedImageFileName)

        let image: UIImage?
        if FileManager.default.fileExists(atPath: imageURL.path),
            let data = try? Data(contentsOf: imageURL),
            let img = UIImage(data: data)
        {
            image = img
        } else {
            image = nil
        }

        await self.updateProfile(name: name, image: image)
    }

    /// Send vibe to friends
    func updateProfile(name: String?, image: UIImage?) async {
        Log.shared.info(
            "[INFO: WelcomeViewModel - updateProfile] Update profile for \(name ?? "") & image"
        )
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasName = !(trimmedName ?? "").isEmpty
        let hasImage = image != nil

        if !hasName && !hasImage {
            Log.shared.error(
                "[ERROR: WelcomeViewModel - updateProfile] No name or image is given, cant update the profile"
            )
            return
        }

        guard let url = URL(string: K.shared.updateProfileURL) else {
            state = .error("Invalid URL")
            return
        }

        state = .loading

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            request.addValue(
                "Bearer \(kc.get(key: K.shared.keyChainUserTokenKey))",
                forHTTPHeaderField: "Authorization"
            )

            let boundary = UUID().uuidString
            request.setValue(
                "multipart/form-data; boundary=\(boundary)",
                forHTTPHeaderField: "Content-Type"
            )

            var body = Data()

            if hasName {
                body.append("--\(boundary)\r\n")
                body.append(
                    "Content-Disposition: form-data; name=\"name\"\r\n\r\n"
                )
                body.append("\(trimmedName!)\r\n")
            }

            if let image = image {

                let shouldResize =
                    image.size.width > 1024 || image.size.height > 1024

                let finalImage: UIImage

                if shouldResize {
                    finalImage = image.resizedToFit(maxDimension: 1024)
                } else {
                    finalImage = image
                }

                if let data = finalImage.jpegData(compressionQuality: 0.8) {

                    body.append("--\(boundary)\r\n")
                    body.append(
                        "Content-Disposition: form-data; name=\"image\"; filename=\"\(K.shared.profileCachedImageFileName)\"\r\n"
                    )
                    body.append("Content-Type: image/jpeg\r\n\r\n")
                    body.append(data)
                    body.append("\r\n")
                }
            }

            body.append("--\(boundary)--\r\n")

            request.httpBody = body

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            if (200...299).contains(http.statusCode) {
                state = .success
            } else {
                state = .error("Server error: \(http.statusCode)")
            }

        } catch {
            state = .error(error.localizedDescription)
        }
    }

}

extension Data {
    mutating func append(_ string: String) {
        append(string.data(using: .utf8)!)
    }
}

extension UIImage {
    func resizedToFitImage(maxDimension: CGFloat) -> UIImage {
        // Don't upscale
        let maxCurrentDimension = max(size.width, size.height)
        guard maxCurrentDimension > maxDimension else {
            return self
        }

        let ratio = maxDimension / maxCurrentDimension

        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

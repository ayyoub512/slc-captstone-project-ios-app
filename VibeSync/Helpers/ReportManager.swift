//
//  ReportManager.swift
//  VibeSync
//
//  Created by Ayyoub on 18/4/2026.
//

import Foundation
import Observation

@Observable
final class ReportManager {
    var state: LoadingState = .idle

    private var token: String {
        KeyChainManager.shared.get(key: K.shared.keyChainUserTokenKey)
    }

    // MARK: - Public API

    func reportMessage(messageId: String, reason: String = "inappropriate")
        async
    {
        await sendReport([
            "type": "message",
            "targetId": messageId,
            "reason": reason,
        ]

        )
    }

    func reportUser(userId: String, reason: String = "inappropriate") async {
        await sendReport(
            [
                "type": "user",
                "targetId": userId,
                "reason": reason,
            ]

        )
    }

    // MARK: - Core request

    private func sendReport(_ body: [String: Any]) async {
        state = .loading
        do {
            guard let reportURL = URL(string: K.shared.reportURL) else {
                return
            }

            var request = URLRequest(url: reportURL)
            request.httpMethod = "POST"
            request.addValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.addValue(
                "Bearer \(self.token)",
                forHTTPHeaderField: "Authorization"
            )

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse,
                200..<300 ~= http.statusCode
            else {
                throw URLError(.badServerResponse)
            }

            state = .success
            Log.shared.info("[INFO: ReportManager - sendReport] Report sent successfully")

        } catch {
            state = .error(error.localizedDescription)
            Log.shared.error("[ERROR: ReportManager - sendReport] \(error)")
        }
    }
}

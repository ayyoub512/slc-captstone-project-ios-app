//
//  widget.swift
//  VibeSync Widget
//

import KeychainSwift
import OSLog
import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    let logger = Logger(subsystem: "io.ayyoub.vibe-sync", category: "Widget")

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), imageURL: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), imageURL: nil))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        Task {
            let imageURL = await fetchLatestImageURL()
            let entry = SimpleEntry(date: Date(), imageURL: imageURL)
            // .atEnd lets the system decide when to refresh;
            // push notifications will force a reload anyway via WidgetCenter
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }

    private func fetchLatestImageURL() async -> String? {
        let kc = KeychainSwift()
        kc.accessGroup = K.shared.keyChainSharedAccessGroup

        guard let token = kc.get(K.shared.keyChainUserTokenKey),
              let url = URL(string: K.shared.getLatestMessageURL)
        else {
            logger.error("Missing token or invalid URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        logger.log("[INFO: widget - fetchLatestImageURL] About to fetch the image")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode)
            else {
                logger.log("[ERROR: widget - fetchLatestImageURL] Bad status code from server")
                return nil
            }

            logger.log("[INFO: widget - fetchLatestImageURL] Lets decde the message")

            let decoded = try JSONDecoder().decode(MessagesResponse.self, from: data)
            logger.log("[INFO: widget - fetchLatestImageURL] decoded: \(String(describing: decoded), privacy: .public)")
            let imageURL = decoded.messages.first?.resizedImageURL
            logger.log("[INFO: widget - fetchLatestImageURL] Fetched image URL: \(imageURL ?? "nil", privacy: .public)")
            return imageURL

        } catch {
            logger.error("[ERROR: widget - fetchLatestImageURL] localizedError: \(String(describing: error.localizedDescription), privacy: .public)")
            logger.log("[ERROR: widget - fetchLatestImageURL] Error: \(String(describing: error), privacy: .public)")

            return nil
        }
    }
}

// MARK: - Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let imageURL: String?
}

// MARK: - Widget View

struct VibeWidgetEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        if let urlString = entry.imageURL, let url = URL(string: urlString) {
            WidgetNetworkImage(url: url)
        } else {
            PlaceholderView()
        }
    }
}
struct PlaceholderView: View {
    var body: some View {
        ZStack {
            // Blurred background image from assets
            Image("WidgetBackground") // your asset name
                .resizable()
                .scaledToFill()
                .overlay(Color.black.opacity(0.35)) // improves contrast
                .clipped()

            VStack(spacing: 10) {
                Spacer()

                // Circle with indigo border
                ZStack {
                    Circle()
                        .stroke(.accent, lineWidth: 2)
                        .frame(width: 64, height: 64)

                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 64, height: 64)

                    Image(systemName: "photo.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                }

                // CTA text
                Text("Tap to configure")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
// MARK: - Network Image
// AsyncImage is unreliable in widgets — synchronous load on background thread is the standard approach

struct WidgetNetworkImage: View {
    let url: URL

    var body: some View {
        if let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                // scaledToFill can overflow — containerBackground clips it
        } else {
            Color.black
        }
    }
}

// MARK: - Push Handler

struct MyWidgetPushHandler: WidgetPushHandler {
    let logger = Logger(subsystem: "io.ayyoub.vibe-sync", category: "WidgetPush")

    func pushTokenDidChange(_ pushInfo: WidgetPushInfo, widgets: [WidgetInfo]) {
        let token = pushInfo.token.map { String(format: "%02x", $0) }.joined()
        logger.log("Widget push token: \(token, privacy: .public)")
        sendTokenToServer(token)
    }

    private func sendTokenToServer(_ token: String) {
        let kc = KeychainSwift()
        kc.accessGroup = K.shared.keyChainSharedAccessGroup

        guard let url = URL(string: K.shared.registerDeviceURL),
              let jwt = kc.get(K.shared.keyChainUserTokenKey)
        else {
            logger.error("Missing URL or JWT for token registration")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "deviceToken": token,
            "isWidget": true
        ])

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error {
                logger.error("Token registration failed: \(error)")
                return
            }
            if let http = response as? HTTPURLResponse {
                logger.log("Token registered, status: \(http.statusCode)")
            }
        }.resume()
    }
}

// MARK: - Widget

struct VibeWidget: Widget {
    let kind = "VibeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VibeWidgetEntryView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Latest Photos")
        .description("Shows the most recent photo shared with you.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .pushHandler(MyWidgetPushHandler.self)
    }
}

// MARK: - Response Models

struct MessagesResponse: Decodable {
    let messages: [MessageEntry]
}

struct MessageEntry: Decodable {
    let _id: String
    var id: String { _id }
    let senderID: String
    let receiverID: String
    let resizedImageURL: String
    let createdAt: String  // MongoDB date string
    let updatedAt: String
}


#Preview(as: .systemSmall) {
    VibeWidget()
} timeline: {
    SimpleEntry(date: .now, imageURL: nil)
}

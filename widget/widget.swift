//
//  widget.swift
//  widget
//
//  Created by Ayyoub on 16/2/2026.
//

import KeychainSwift
import OSLog
import SwiftUI
import WidgetKit

// Responsible for managing the data and timeline of your widget
struct Provider: AppIntentTimelineProvider {
    let logger = Logger(
        subsystem: "io.ayyoub.vibe-sync",
        category: "WidgetPush"
    )
    
    let imgPlaceHolder = "https://bucket-vibe-sync.s3.us-west-2.amazonaws.com/eaa70e71d096c729dd54c0430ab53a7d.jpg"
    
    // Helper function to call your GetMessagesByFriendController
    func fetchLatestImage() async -> String? {
        logger.log("Widgey: Fetching latest widget image")
        let kc = KeychainSwift()
        let friendID = "699e1c1fce42532ffd4c2e57"
        kc.accessGroup = K.shared.keyChainSharedAccessGroup

        // 1. Get Auth Token
        guard let token = kc.get(K.shared.keyChainUserTokenKey) else {
            return nil
        }

        guard let url = URL(string: K.shared.apiURL + "/getMessagesByFriend")
        else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "friendID": friendID
        ])

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(
                MessagesResponse.self,
                from: data
            )
            
            logger.log("Widget: Got the image ")
            // Get the imageURL from the very last message in the array
            return response.messages.last?.imageURL
        } catch {
            return nil
        }
    }

    // Sets up a default widget entry.
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), imageURL: imgPlaceHolder)
    }

    // Defines how your widget should look in a static state
    func snapshot(
        for configuration: ConfigurationAppIntent,
        in context: Context
    ) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, imageURL: imgPlaceHolder)
    }

    // Generates the timeline entries for widget, specifying when and how often the widget's data should be refreshed.
    func timeline(
        for configuration: ConfigurationAppIntent,
        in context: Context
    ) async -> Timeline<SimpleEntry> {
        // 1. Fetch the latest image URL from your backend
        // You'll need your user token from Keychain here too!
        let latestImageURL = await fetchLatestImage()

        // 2. Create the entry with the new data
        let entry = SimpleEntry(
            date: Date(),
            configuration: configuration,
            imageURL: latestImageURL
        )

        // 3. Return the timeline (policy .atEnd or .never since push handles refreshes)
        return Timeline(entries: [entry], policy: .atEnd)
    }
}

// represents a single entry in your widget's timeline and holds essential data like the date
struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let imageURL: String?
}

// Widget view
struct widgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            if let urlString = entry.imageURL, let url = URL(string: urlString)
            {
                NetworkImage(url: url)  // Use a custom view for Widget images
            } else {
                Text("Image goes here")
            }

            
        }
        .containerBackground(.black.gradient, for: .widget)
    }
}

struct MyWidgetPushHandler: WidgetPushHandler {
    let logger = Logger(
        subsystem: "io.ayyoub.vibe-sync",
        category: "WidgetPush"
    )

    func pushTokenDidChange(_ pushInfo: WidgetPushInfo, widgets: [WidgetInfo]) {
        let pushTokenString = pushInfo.token.map { String(format: "%02x", $0) }
            .joined()

        logger.log(
            "Syncing Widget Push Token: \(pushTokenString, privacy: .public)"
        )
        sendDeviceTokenToServer(with: pushTokenString)

        logger.log("I am here!")
    }

    func sendDeviceTokenToServer(with token: String) {
        let keyChain = KeychainSwift()
        keyChain.accessGroup = K.shared.keyChainSharedAccessGroup
        // Let's make sure it hasn't change yet
        guard let url = URL(string: K.shared.registerDeviceURL) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let jwtToken = keyChain.get(K.shared.keyChainUserTokenKey) else {
            logger.error(
                "No jwt token is stored in chain to be used for APNs server device registeration"
            )
            return
        }
        request.addValue(
            "Bearer \(jwtToken)",
            forHTTPHeaderField: "Authorization"
        )

        let body: [String: Any] = [
            "deviceToken": token,
            "isWidget": true,
        ]
        request.httpBody = try? JSONSerialization.data(
            withJSONObject: body,
            options: []
        )

        URLSession.shared.dataTask(with: request) { data, response, error in
            logger.log("Request was made")
            if let error = error {
                logger.error("Error sending device token: \(error)")
                return
            }

            if let response = response as? HTTPURLResponse {
                logger.log(
                    "Device token sent. Status code: \(response.statusCode)"
                )
            }
        }.resume()
    }
}

// Main struct conforming to the Widget protocol
struct widget: Widget {
    let kind: String = "widget"  //  identifier for widget.

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            widgetEntryView(entry: entry)

        }
        .configurationDisplayName("Viby Sycn Cool Widget")
        .pushHandler(MyWidgetPushHandler.self)
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }

    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

struct MessagesResponse: Decodable {
    let message: String
    let messages: [MessageEntry]
}

struct MessageEntry: Decodable {
    let senderID: String
    let receiverID: String
    let imageURL: String
    let createdAt: String // Capturing as String; can be converted to Date later

    enum CodingKeys: String, CodingKey {
        case senderID, receiverID, imageURL
        case createdAt = "created_at" // Maps from snake_case in your Mongoose select
    }
}


// Helper struct for decoding
struct LatestImageResponse: Codable {
    let imageURL: String
}

// Widgets need a simple way to load images; AsyncImage can be flaky in Widgets
struct NetworkImage: View {
    let url: URL
    var body: some View {
        if let data = try? Data(contentsOf: url),
            let uiImage = UIImage(data: data)
        {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Color.gray
        }
    }
}

//#Preview(as: .systemSmall) {
//    widget()
//} timeline: {
//    SimpleEntry(date: .now, configuration: .smiley)
//    SimpleEntry(date: .now, configuration: .starEyes)
//}

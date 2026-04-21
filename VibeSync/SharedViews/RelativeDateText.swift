//
//  RelativeDateText.swift
//  VibeSync
//
//  Created by Ayyoub on 21/4/2026.
//

import SwiftUI

struct RelativeDateText: View {
    let date: Date

    var body: some View {
        TimelineView(schedule(for: date)) { context in
            Text(date.formattedRelative)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func schedule(for date: Date) -> PeriodicTimelineSchedule {
        let age = Date.now.timeIntervalSince(date)
        let interval: TimeInterval

        if age < 60 {
            interval = 1
        } else if age < 3600 {
            interval = 60
        } else if age < 86400 {
            interval = 3600
        } else {
            interval = 86400
        }

        return .periodic(from: date, by: interval)
    }
}

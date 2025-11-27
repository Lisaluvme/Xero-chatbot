//
//  GensetWatchWidget.swift
//  GensetWatchWidget
//
//  Created on 2025-01-11.
//  Copyright © 2024 Mega GenSet. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct GensetWatchEntry: TimelineEntry {
    let date: Date
    let gensetName: String
    let status: String
    let power: String
    let fuelLevel: String
    let runtime: String
    let nextMaintenance: String?
    let location: String
    let lastUpdate: String
}

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> GensetWatchEntry {
        GensetWatchEntry(
            date: Date(),
            gensetName: "Generator 1",
            status: "Online",
            power: "45 kW",
            fuelLevel: "78%",
            runtime: "3h 15m",
            nextMaintenance: "2024-02-15",
            location: "Main Building",
            lastUpdate: "Just now"
        )
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (GensetWatchEntry) -> ()) {
        let entry = fetchCurrentGensetData()
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<GensetWatchEntry>) -> ()) {

        let currentData = fetchCurrentGensetData()

        // Create timeline with current data
        let entries = [currentData]

        // Refresh every 10 minutes (Apple Watch uses different scheduling)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!

        let timeline = Timeline(entries: entries, policy: .after(nextRefresh))
        completion(timeline)
    }

    private func fetchCurrentGensetData() -> GensetWatchEntry {
        // Fetch from shared UserDefaults (populated by main iOS app)
        let userDefaults = UserDefaults(suiteName: "group.com.mega.gensetassistant")
        let gensetData = userDefaults?.dictionary(forKey: "currentGenset") as? [String: Any] ?? [:]

        // Extract data with fallbacks
        let gensetName = gensetData["name"] as? String ?? "Generator 1"
        let status = gensetData["status"] as? String ?? "Offline"
        let power = gensetData["power"] as? String ?? "0 kW"
        let fuelLevel = gensetData["fuel"] as? String ?? "--"
        let runtime = gensetData["runtime"] as? String ?? "0h"
        let nextMaintenance = gensetData["nextMaintenance"] as? String
        let location = gensetData["location"] as? String ?? "Unknown"
        let timestamp = gensetData["timestamp"] as? Double ?? Date().timeIntervalSince1970
        let lastUpdateDate = Date(timeIntervalSince1970: timestamp)

        // Calculate time since last update
        let timeSinceUpdate = Calendar.current.dateComponents([.minute, .hour], from: lastUpdateDate, to: Date())
        let lastUpdateText: String
        if let hours = timeSinceUpdate.hour, hours > 0 {
            lastUpdateText = "\(hours)h"
        } else if let minutes = timeSinceUpdate.minute {
            lastUpdateText = "\(minutes)m"
        } else {
            lastUpdateText = "now"
        }

        return GensetWatchEntry(
            date: Date(),
            gensetName: gensetName,
            status: status,
            power: power,
            fuelLevel: fuelLevel,
            runtime: runtime,
            nextMaintenance: nextMaintenance,
            location: location,
            lastUpdate: lastUpdateText
        )
    }
}

struct GensetWatchEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if widgetFamily == .accessoryCircular {
            // Circular complication for watch face
            ZStack {
                Circle()
                    .fill(statusColor)
                    .opacity(0.2)
                VStack(spacing: 0) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 16))
                    if statusColor == .green {
                        Text("ON")
                            .font(.system(size: 8, weight: .bold))
                    } else {
                        Text("OFF")
                            .font(.system(size: 8, weight: .bold))
                    }
                }
            }
        } else {
            // Accessory rectangular widget
            HStack(alignment: .top, spacing: 4) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        Text(entry.gensetName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(entry.status.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(statusColor)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Text(entry.power)
                            .font(.system(size: 10))
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "fuelpump.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Text(entry.fuelLevel)
                            .font(.system(size: 10))
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Text("\(entry.runtime) ago")
                            .font(.system(size: 10))
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
        }
    }

    private var statusColor: Color {
        switch entry.status.lowercased() {
        case "online", "running", "active":
            return .green
        case "offline", "stopped", "idle":
            return .red
        case "standby", "maintenance":
            return .orange
        case "alarm", "error", "fault":
            return .red
        default:
            return .gray
        }
    }
}

@main
struct GensetWatchWidget: Widget {
    let kind: String = "GensetWatchWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: Provider()
        ) { entry in
            GensetWatchEntryView(entry: entry)
                .background(Color(.black))
        }
        .configurationDisplayName("Genset Monitor")
        .description("Monitor your generator status")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

struct GensetWatchWidget_Previews: PreviewProvider {
    static var previews: some View {
        GensetWatchEntryView(entry: GensetWatchEntry(
            date: Date(),
            gensetName: "Generator 1",
            status: "Running",
            power: "45 kW",
            fuelLevel: "78%",
            runtime: "3h 15m",
            nextMaintenance: "2024-02-15",
            location: "Main Building",
            lastUpdate: "Just now"
        ))
        .previewContext(WidgetPreviewContext(family: .accessoryRectangular))

        GensetWatchEntryView(entry: GensetWatchEntry(
            date: Date(),
            gensetName: "Generator 1",
            status: "Running",
            power: "45 kW",
            fuelLevel: "78%",
            runtime: "3h 15m",
            nextMaintenance: "2024-02-15",
            location: "Main Building",
            lastUpdate: "Just now"
        ))
        .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}

//
//  GensetWidgetExtension.swift
//  GensetWidgetExtension
//
//  Created on 2025-01-11.
//  Copyright © 2024 Mega GenSet. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct GensetWidgetEntry: TimelineEntry {
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
    func placeholder(in context: Context) -> GensetWidgetEntry {
        GensetWidgetEntry(
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

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (GensetWidgetEntry) -> ()) {
        let entry = fetchCurrentGensetData()
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<GensetWidgetEntry>) -> ()) {

        let currentData = fetchCurrentGensetData()

        // Create timeline with current data
        let entries = [currentData]

        // Refresh every 5 minutes
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!

        let timeline = Timeline(entries: entries, policy: .after(nextRefresh))
        completion(timeline)
    }

    private func fetchCurrentGensetData() -> GensetWidgetEntry {
        // Fetch from shared UserDefaults (populated by main iOS app)
        let userDefaults = UserDefaults(suiteName: "group.com.mega.gensetassistant.ios")
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
            lastUpdateText = "\(hours)h ago"
        } else if let minutes = timeSinceUpdate.minute {
            lastUpdateText = "\(minutes)m ago"
        } else {
            lastUpdateText = "Just now"
        }

        return GensetWidgetEntry(
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

struct SmallGensetWidgetView: View {
    let entry: GensetWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title with status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                Text(entry.gensetName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }

            // Status badge
            Text(entry.status.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(statusColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.1))
                .cornerRadius(3)

            // Key metrics
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    Text(entry.power)
                        .font(.system(size: 10, weight: .medium))
                }

                HStack(spacing: 2) {
                    Image(systemName: "fuelpump.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    Text(entry.fuelLevel)
                        .font(.system(size: 10))
                }
            }

            Spacer()

            // Last update timestamp
            Text(entry.lastUpdate)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .padding(8)
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

struct MediumGensetWidgetView: View {
    let entry: GensetWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator and main info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(entry.gensetName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }

                Text(entry.status.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(4)

                Text(entry.location)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Divider()

            // Detailed metrics
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("Power")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Text(entry.power)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "fuelpump.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("Fuel")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Text(entry.fuelLevel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("Runtime")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Text(entry.runtime)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }

                if let maintenanceDate = entry.nextMaintenance {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text("Maint")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        Text(maintenanceDate)
                            .font(.system(size: 11))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(12)
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

struct GensetWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    @ViewBuilder
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallGensetWidgetView(entry: entry)
        case .systemMedium:
            MediumGensetWidgetView(entry: entry)
        default:
            SmallGensetWidgetView(entry: entry)
        }
    }
}

@main
struct GensetWidgetExtension: Widget {
    let kind: String = "GensetWidgetExtension"

    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: Provider()
        ) { entry in
            GensetWidgetEntryView(entry: entry)
                .background(Color(.systemBackground))
        }
        .configurationDisplayName("Genset Monitor")
        .description("Monitor your generator status at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct GensetWidgetExtension_Previews: PreviewProvider {
    static var previews: some View {
        GensetWidgetEntryView(entry: GensetWidgetEntry(
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
        .previewContext(WidgetPreviewContext(family: .systemSmall))

        GensetWidgetEntryView(entry: GensetWidgetEntry(
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
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

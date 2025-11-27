//
//  ContentView.swift
//  GAWatchApp Watch App
//
//  Created on 2025-01-11.
//  Copyright © 2024 Mega GenSet. All rights reserved.
//

import SwiftUI
import WatchConnectivity
import WatchKit

struct GensetData: Codable, Identifiable {
    var id = UUID()
    var name: String
    var status: String
    var power: String
    var fuel: String
    var runtime: String
    var lastMaintenance: String
    var location: String

    init(name: String = "Generator 1",
         status: String = "Offline",
         power: String = "0 kW",
         fuel: String = "75%",
         runtime: String = "0h 0m",
         lastMaintenance: String = "N/A",
         location: String = "Unknown") {
        self.name = name
        self.status = status
        self.power = power
        self.fuel = fuel
        self.runtime = runtime
        self.lastMaintenance = lastMaintenance
        self.location = location
    }
}

class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    @Published var currentGenset: GensetData = GensetData()

    private let session: WCSession

    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Watch session activation failed: \(error.localizedDescription)")
        } else {
            print("Watch session activated: \(activationState.rawValue)")
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    #endif

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.updateGensetData(from: applicationContext)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.updateGensetData(from: message)
        }
    }

    private func updateGensetData(from data: [String: Any]) {
        let name = data["name"] as? String ?? "Generator 1"
        let status = data["status"] as? String ?? "Offline"
        let power = data["power"] as? String ?? "0 kW"
        let fuel = data["fuel"] as? String ?? "75%"
        let runtime = data["runtime"] as? String ?? "0h 0m"
        let lastMaintenance = data["lastMaintenance"] as? String ?? "N/A"
        let location = data["location"] as? String ?? "Unknown"

        self.currentGenset = GensetData(
            name: name,
            status: status,
            power: power,
            fuel: fuel,
            runtime: runtime,
            lastMaintenance: lastMaintenance,
            location: location
        )
    }

    func sendMessageToiOS() {
        let message = ["requestGensetData": true]
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("Error sending message: \(error.localizedDescription)")
        })
    }
}

struct GensetStatusView: View {
    let data: GensetData

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(data.status)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)
            }

            Text(data.name)
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.center)

            VStack(spacing: 4) {
                GensetMetricView(label: "Power", value: data.power)
                GensetMetricView(label: "Fuel", value: data.fuel)
                GensetMetricView(label: "Runtime", value: data.runtime)
                GensetMetricView(label: "Maintenance", value: data.lastMaintenance)
            }
        }
        .padding()
    }

    private var statusColor: Color {
        switch data.status.lowercased() {
        case "online", "running":
            return .green
        case "offline", "stopped":
            return .red
        case "standby", "idle":
            return .orange
        default:
            return .gray
        }
    }
}

struct GensetMetricView: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .medium))
        }
    }
}

struct ContentView: View {
    @StateObject private var sessionManager = WatchSessionManager()

    var body: some View {
        TabView {
            // Main Genset Status
            GensetStatusView(data: sessionManager.currentGenset)
                .tabItem {
                    Image(systemName: "gauge.medium")
                    Text("Status")
                }

            // Quick Actions
            QuickActionsView()
                .tabItem {
                    Image(systemName: "bolt")
                    Text("Actions")
                }

            // Settings
            SettingsView(sessionManager: sessionManager)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .tabViewStyle(.page)
        .onAppear {
            sessionManager.sendMessageToiOS()
        }
    }
}

struct QuickActionsView: View {
    var body: some View {
        VStack(spacing: 15) {
            Text("Quick Actions")
                .font(.headline)

            VStack(spacing: 10) {
                QuickActionButton(
                    icon: "play.circle.fill",
                    title: "Start Generator",
                    color: .green
                )

                QuickActionButton(
                    icon: "stop.circle.fill",
                    title: "Stop Generator",
                    color: .red
                )

                QuickActionButton(
                    icon: "bell.circle.fill",
                    title: "Schedule Alert",
                    color: .blue
                )
            }

            Spacer()
        }
        .padding(.vertical)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button(action: {
            // Send action to iOS app via Watch Connectivity
            let session = WCSession.default
            if session.isReachable {
                session.sendMessage(["action": title], replyHandler: nil, errorHandler: nil)
            }
            // Provide haptic feedback
            WKInterfaceDevice.current().play(.click)
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10))
                    .multilineTextAlignment(.center)
            }
            .frame(height: 50)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var sessionManager: WatchSessionManager

    var body: some View {
        VStack(spacing: 15) {
            Text("Settings")
                .font(.headline)

            VStack(spacing: 10) {
                Button("Refresh Data") {
                    sessionManager.sendMessageToiOS()
                    WKInterfaceDevice.current().play(.click)
                }
                .foregroundColor(.blue)

                Button("Check Status") {
                    // Send ping to iOS app
                    WCSession.default.sendMessage(["ping": true], replyHandler: nil, errorHandler: nil)
                    WKInterfaceDevice.current().play(.click)
                }
                .foregroundColor(.green)
            }

            Spacer()

            VStack(spacing: 4) {
                Text("Genset Assistant")
                    .font(.system(size: 10, weight: .medium))
                Text("Watch Edition")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

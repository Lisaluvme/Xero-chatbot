//
//  watchkit.swift
//  watchkit
//
//  Created by MGM Admin on 13/11/2025.
//

import AppIntents

struct watchkit: AppIntent {
    static var title: LocalizedStringResource { "watchkit" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

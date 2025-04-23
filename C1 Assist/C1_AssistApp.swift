//
//  C1_AssistApp.swift
//  C1 Assist
//
//  Created by Koray Birand on 23/04/2025.
//

import SwiftUI

@main
struct C1_AssistApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 400)
        .windowStyle(.automatic)
        .defaultPosition(.center)
    }
}

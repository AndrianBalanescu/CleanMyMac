//
//  CleanMyMacApp.swift
//  CleanMyMac
//
//  Created on macOS 13+
//

import SwiftUI

@main
struct CleanMyMacApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 1000, minHeight: 700)
                .background(.ultraThinMaterial)
                .translucentWindow()
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}


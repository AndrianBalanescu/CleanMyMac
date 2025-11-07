//
//  InstalledApp.swift
//  CleanMyMac
//
//  Data model for installed applications
//

import Foundation
import AppKit

struct InstalledApp: Identifiable, Codable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let version: String
    let path: String
    let size: Int64
    let icon: Data?
    let metadata: AppMetadata?
    let cliTools: [CLITool]
    let keyboardShortcuts: [KeyboardShortcut]
    
    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var iconImage: NSImage? {
        guard let icon = icon else { return nil }
        return NSImage(data: icon)
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         bundleIdentifier: String,
         version: String,
         path: String,
         size: Int64,
         icon: Data? = nil,
         metadata: AppMetadata? = nil,
         cliTools: [CLITool] = [],
         keyboardShortcuts: [KeyboardShortcut] = []) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.path = path
        self.size = size
        self.icon = icon
        self.metadata = metadata
        self.cliTools = cliTools
        self.keyboardShortcuts = keyboardShortcuts
    }
}


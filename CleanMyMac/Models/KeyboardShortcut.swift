//
//  KeyboardShortcut.swift
//  CleanMyMac
//
//  Keyboard shortcut information
//

import Foundation
import AppKit

struct KeyboardShortcut: Identifiable, Codable {
    let id: String
    let key: String
    let modifiers: [String]
    let action: String
    let appName: String?
    let appBundleId: String?
    let isSystemShortcut: Bool
    let isCustom: Bool
    
    var displayString: String {
        var result = modifiers.joined(separator: "+")
        if !result.isEmpty {
            result += "+"
        }
        result += key
        return result
    }
    
    var modifierSymbols: String {
        modifiers.map { symbol(for: $0) }.joined()
    }
    
    private func symbol(for modifier: String) -> String {
        switch modifier.lowercased() {
        case "command", "cmd": return "⌘"
        case "control", "ctrl": return "⌃"
        case "option", "alt": return "⌥"
        case "shift": return "⇧"
        default: return modifier
        }
    }
    
    init(id: String = UUID().uuidString,
         key: String,
         modifiers: [String],
         action: String,
         appName: String? = nil,
         appBundleId: String? = nil,
         isSystemShortcut: Bool = false,
         isCustom: Bool = false) {
        self.id = id
        self.key = key
        self.modifiers = modifiers
        self.action = action
        self.appName = appName
        self.appBundleId = appBundleId
        self.isSystemShortcut = isSystemShortcut
        self.isCustom = isCustom
    }
}


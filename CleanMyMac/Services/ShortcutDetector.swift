//
//  ShortcutDetector.swift
//  CleanMyMac
//
//  Detect keyboard shortcuts
//

import Foundation
import AppKit

class ShortcutDetector {
    static let shared = ShortcutDetector()
    
    private init() {}
    
    func detectShortcuts(for bundleId: String) async -> [KeyboardShortcut] {
        var shortcuts: [KeyboardShortcut] = []
        
        // System shortcuts
        shortcuts.append(contentsOf: await getSystemShortcuts(for: bundleId))
        
        // App-specific shortcuts from menu items
        shortcuts.append(contentsOf: await getAppMenuShortcuts(for: bundleId))
        
        return shortcuts
    }
    
    private func getSystemShortcuts(for bundleId: String) async -> [KeyboardShortcut] {
        var shortcuts: [KeyboardShortcut] = []
        
        // Read from symbolic hotkeys plist
        let plistPath = NSHomeDirectory() + "/Library/Preferences/com.apple.symbolichotkeys.plist"
        
        guard let plistData = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
              let appleSymbolicHotKeys = plist["AppleSymbolicHotKeys"] as? [String: Any] else {
            return shortcuts
        }
        
        // Parse system shortcuts (these are global, not app-specific)
        // This is a simplified version - full implementation would parse all shortcuts
        for (key, value) in appleSymbolicHotKeys {
            if let hotKey = value as? [String: Any],
               let enabled = hotKey["enabled"] as? Bool,
               enabled,
               let valueDict = hotKey["value"] as? [String: Any],
               let parameters = valueDict["parameters"] as? [Any],
               parameters.count >= 2 {
                
                let keyCode = parameters[0] as? Int ?? 0
                let modifiers = parameters[1] as? Int ?? 0
                
                let key = keyCodeToString(keyCode)
                let modifierStrings = modifiersToString(modifiers)
                
                shortcuts.append(KeyboardShortcut(
                    key: key,
                    modifiers: modifierStrings,
                    action: "System: \(key)",
                    isSystemShortcut: true,
                    isCustom: false
                ))
            }
        }
        
        return shortcuts
    }
    
    private func getAppMenuShortcuts(for bundleId: String) async -> [KeyboardShortcut] {
        // This would require accessing the app's menu structure
        // For now, return empty - this would need NSRunningApplication and menu inspection
        // which is complex and may require the app to be running
        return []
    }
    
    private func keyCodeToString(_ keyCode: Int) -> String {
        // Map key codes to strings (simplified)
        let keyMap: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            // Add more mappings as needed
        ]
        return keyMap[keyCode] ?? "Key\(keyCode)"
    }
    
    private func modifiersToString(_ modifiers: Int) -> [String] {
        var mods: [String] = []
        
        if modifiers & 0x100000 == 0x100000 {
            mods.append("Command")
        }
        if modifiers & 0x200000 == 0x200000 {
            mods.append("Shift")
        }
        if modifiers & 0x400000 == 0x400000 {
            mods.append("Control")
        }
        if modifiers & 0x800000 == 0x800000 {
            mods.append("Option")
        }
        
        return mods
    }
    
    func getAllSystemShortcuts() async -> [KeyboardShortcut] {
        return await getSystemShortcuts(for: "")
    }
}


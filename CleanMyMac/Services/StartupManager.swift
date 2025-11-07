//
//  StartupManager.swift
//  CleanMyMac
//
//  Manage startup items
//

import Foundation
import AppKit

@MainActor
class StartupManager: ObservableObject {
    @Published var startupItems: [StartupItem] = []
    @Published var isLoading = false
    
    func scanStartupItems() async {
        isLoading = true
        defer { isLoading = false }
        
        var items: [StartupItem] = []
        
        // Scan Launch Agents
        let launchAgentPath = NSHomeDirectory() + "/Library/LaunchAgents"
        items.append(contentsOf: await scanLaunchAgents(at: launchAgentPath))
        
        // Scan Login Items
        items.append(contentsOf: await scanLoginItems())
        
        startupItems = items
    }
    
    private func scanLaunchAgents(at path: String) async -> [StartupItem] {
        var items: [StartupItem] = []
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: path),
              let contents = try? fileManager.contentsOfDirectory(atPath: path) else {
            return items
        }
        
        for item in contents where item.hasSuffix(".plist") {
            let itemPath = (path as NSString).appendingPathComponent(item)
            
            // Read plist to get info
            if let plistData = try? Data(contentsOf: URL(fileURLWithPath: itemPath)),
               let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
               let label = plist["Label"] as? String {
                
                let isEnabled = plist["RunAtLoad"] as? Bool ?? true
                
                items.append(StartupItem(
                    name: label,
                    path: itemPath,
                    type: .launchAgent,
                    isEnabled: isEnabled
                ))
            }
        }
        
        return items
    }
    
    private func scanLoginItems() async -> [StartupItem] {
        var items: [StartupItem] = []
        
        // Get login items from System Preferences
        let loginItems = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeUnretainedValue(), nil)
        
        guard let loginItems = loginItems?.takeRetainedValue() else {
            return items
        }
        
        // This is a simplified version - full implementation would iterate through login items
        // For now, return empty array
        
        return items
    }
    
    func disableStartupItem(_ item: StartupItem) throws {
        // Disable by modifying plist or removing from login items
        // Implementation would depend on item type
    }
    
    func enableStartupItem(_ item: StartupItem) throws {
        // Enable by modifying plist or adding to login items
    }
    
    func removeStartupItem(_ item: StartupItem) throws {
        let fileManager = FileManager.default
        try fileManager.removeItem(atPath: item.path)
        startupItems.removeAll { $0.id == item.id }
    }
}


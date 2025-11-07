//
//  MetadataExtractor.swift
//  CleanMyMac
//
//  Extract extended app metadata
//

import Foundation
import AppKit

class MetadataExtractor {
    static let shared = MetadataExtractor()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    func extractMetadata(for app: InstalledApp) async -> AppMetadata {
        let bundle = Bundle(path: app.path)
        
        // Installation date - use file creation date
        let installationDate = getInstallationDate(for: app.path)
        
        // Last used date - from Launch Services
        let lastUsedDate = await getLastUsedDate(for: app.bundleIdentifier)
        
        // Launch count - approximate from usage
        let launchCount = await getLaunchCount(for: app.bundleIdentifier)
        
        // Category detection
        let category = detectCategory(for: app, bundle: bundle)
        
        // Developer info
        let developer = bundle?.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
        let copyright = bundle?.object(forInfoDictionaryKey: "CFBundleGetInfoString") as? String
        
        // App Store detection
        let isAppStoreApp = checkIfAppStoreApp(bundle: bundle, path: app.path)
        
        // Permissions
        let permissions = extractPermissions(bundle: bundle)
        
        // Background processes
        let backgroundProcesses = await detectBackgroundProcesses(for: app.bundleIdentifier)
        
        return AppMetadata(
            installationDate: installationDate,
            lastUsedDate: lastUsedDate,
            launchCount: launchCount,
            category: category,
            developer: developer,
            copyright: copyright,
            isAppStoreApp: isAppStoreApp,
            updateAvailable: false, // TODO: Implement update checking
            permissions: permissions,
            backgroundProcesses: backgroundProcesses
        )
    }
    
    private func getInstallationDate(for path: String) -> Date? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: path),
              let creationDate = attributes[.creationDate] as? Date else {
            return nil
        }
        return creationDate
    }
    
    private func getLastUsedDate(for bundleId: String) async -> Date? {
        // Use lsappinfo to get last used date
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/lsappinfo")
        process.arguments = ["info", "-only", "LSLastUsedDate", bundleId]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            // Parse output to extract date
            // Format: LSLastUsedDate="2024-01-15 10:30:00 +0000"
            if let dateRange = output.range(of: "LSLastUsedDate=\""),
               let endRange = output.range(of: "\"", range: dateRange.upperBound..<output.endIndex) {
                let dateString = String(output[dateRange.upperBound..<endRange.lowerBound])
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                return formatter.date(from: dateString)
            }
        } catch {
            // Fallback: use file modification date
            return nil
        }
        
        return nil
    }
    
    private func getLaunchCount(for bundleId: String) async -> Int {
        // Approximate launch count from usage patterns
        // This is a simplified version - full implementation would track launches
        return 0 // TODO: Implement launch count tracking
    }
    
    private func detectCategory(for app: InstalledApp, bundle: Bundle?) -> AppMetadata.AppCategory? {
        let name = app.name.lowercased()
        let bundleId = app.bundleIdentifier.lowercased()
        
        // Developer tools
        if name.contains("xcode") || name.contains("code") || name.contains("developer") ||
           bundleId.contains("com.apple.dt") || bundleId.contains("developer") {
            return .developer
        }
        
        // Productivity
        if name.contains("notes") || name.contains("pages") || name.contains("keynote") ||
           name.contains("word") || name.contains("excel") || name.contains("powerpoint") {
            return .productivity
        }
        
        // Entertainment
        if name.contains("music") || name.contains("spotify") || name.contains("netflix") {
            return .entertainment
        }
        
        // Graphics
        if name.contains("photoshop") || name.contains("illustrator") || name.contains("sketch") ||
           name.contains("figma") {
            return .graphics
        }
        
        // Utilities
        if name.contains("clean") || name.contains("utility") || name.contains("tool") {
            return .utilities
        }
        
        return nil
    }
    
    private func checkIfAppStoreApp(bundle: Bundle?, path: String) -> Bool {
        // Check for App Store receipt
        if let receiptPath = bundle?.appStoreReceiptURL {
            return FileManager.default.fileExists(atPath: receiptPath.path)
        }
        
        // Check if in /Applications (App Store apps are usually there)
        if path.contains("/Applications/") && !path.contains("/Users/") {
            // Additional check: look for _MASReceipt
            let masReceiptPath = (path as NSString).appendingPathComponent("Contents/_MASReceipt")
            return FileManager.default.fileExists(atPath: masReceiptPath)
        }
        
        return false
    }
    
    private func extractPermissions(bundle: Bundle?) -> [String] {
        var permissions: [String] = []
        
        // Check Info.plist for permission usage descriptions
        if let infoDict = bundle?.infoDictionary {
            let permissionKeys = [
                "NSPhotoLibraryUsageDescription",
                "NSCameraUsageDescription",
                "NSMicrophoneUsageDescription",
                "NSLocationWhenInUseUsageDescription",
                "NSContactsUsageDescription",
                "NSCalendarsUsageDescription",
                "NSRemindersUsageDescription",
                "NSDesktopFolderUsageDescription",
                "NSDownloadsFolderUsageDescription"
            ]
            
            for key in permissionKeys {
                if infoDict[key] != nil {
                    let permissionName = key.replacingOccurrences(of: "NS", with: "")
                        .replacingOccurrences(of: "UsageDescription", with: "")
                    permissions.append(permissionName)
                }
            }
        }
        
        return permissions
    }
    
    private func detectBackgroundProcesses(for bundleId: String) async -> [String] {
        // Check for Launch Agents and Daemons
        var processes: [String] = []
        
        let launchAgentPath = NSHomeDirectory() + "/Library/LaunchAgents"
        if let contents = try? fileManager.contentsOfDirectory(atPath: launchAgentPath) {
            for item in contents {
                if item.contains(bundleId) {
                    processes.append(item)
                }
            }
        }
        
        return processes
    }
}


//
//  AppManager.swift
//  CleanMyMac
//
//  Handles app discovery, uninstallation, cache detection
//

import Foundation
import AppKit

@MainActor
class AppManager: ObservableObject {
    @Published var installedApps: [InstalledApp] = []
    @Published var isLoading = false
    @Published var selectedApp: InstalledApp?
    @Published var appCaches: [CacheLocation] = []
    @Published var leftoverFiles: [String] = []
    
    private let fileManager = FileManager.default
    private let fileSystemScanner = FileSystemScanner.shared
    
    func scanInstalledApps() async {
        isLoading = true
        defer { isLoading = false }
        
        var apps: [InstalledApp] = []
        let applicationPaths = [
            "/Applications",
            NSHomeDirectory() + "/Applications"
        ]
        
        for appPath in applicationPaths {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: appPath) else {
                continue
            }
            
            for item in contents {
                let fullPath = (appPath as NSString).appendingPathComponent(item)
                
                // Check if it's an .app bundle
                guard item.hasSuffix(".app") else { continue }
                
                if let app = await createAppInfo(from: fullPath) {
                    apps.append(app)
                }
            }
        }
        
        installedApps = apps.sorted { $0.name < $1.name }
    }
    
    private func createAppInfo(from path: String) async -> InstalledApp? {
        guard let bundle = Bundle(path: path) else { return nil }
        
        let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ??
                   bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
                   (path as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
        
        let bundleId = bundle.bundleIdentifier ?? "unknown"
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        
        // Calculate app size
        let size = await calculateAppSize(at: path)
        
        // Get app icon
        var iconData: Data?
        if let iconPath = bundle.path(forResource: "AppIcon", ofType: "icns"),
           let image = NSImage(contentsOfFile: iconPath) {
            iconData = image.tiffRepresentation
        } else if let iconFile = bundle.object(forInfoDictionaryKey: "CFBundleIconFile") as? String,
                  let iconPath = bundle.path(forResource: (iconFile as NSString).deletingPathExtension, ofType: "icns"),
                  let image = NSImage(contentsOfFile: iconPath) {
            iconData = image.tiffRepresentation
        }
        
        return InstalledApp(
            name: name,
            bundleIdentifier: bundleId,
            version: version,
            path: path,
            size: size,
            icon: iconData
        )
    }
    
    private func calculateAppSize(at path: String) async -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            return 0
        }
        
        for case let file as String in enumerator {
            let filePath = (path as NSString).appendingPathComponent(file)
            
            do {
                let attributes = try fileManager.attributesOfItem(atPath: filePath)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    func selectApp(_ app: InstalledApp) async {
        selectedApp = app
        await loadAppDetails(for: app)
    }
    
    private func loadAppDetails(for app: InstalledApp) async {
        // Load caches
        appCaches = await fileSystemScanner.scanCacheDirectory(for: app.bundleIdentifier)
        
        // Load leftover files
        leftoverFiles = await fileSystemScanner.scanLeftoverFiles(for: app.bundleIdentifier)
    }
    
    func uninstallApp(_ app: InstalledApp) async throws {
        // Delete the app bundle
        try fileManager.removeItem(atPath: app.path)
        
        // Delete caches
        for cache in appCaches {
            try? fileSystemScanner.deleteCache(at: cache.path)
        }
        
        // Delete leftover files
        for leftoverPath in leftoverFiles {
            try? fileSystemScanner.deleteLeftoverFile(at: leftoverPath)
        }
        
        // Remove from list
        installedApps.removeAll { $0.id == app.id }
        
        if selectedApp?.id == app.id {
            selectedApp = nil
            appCaches = []
            leftoverFiles = []
        }
    }
    
    func deleteCache(_ cache: CacheLocation) throws {
        try fileSystemScanner.deleteCache(at: cache.path)
        appCaches.removeAll { $0.id == cache.id }
    }
    
    func deleteLeftoverFile(at path: String) throws {
        try fileSystemScanner.deleteLeftoverFile(at: path)
        leftoverFiles.removeAll { $0 == path }
    }
}


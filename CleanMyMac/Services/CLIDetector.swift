//
//  CLIDetector.swift
//  CleanMyMac
//
//  Detect CLI tools provided by apps
//

import Foundation

class CLIDetector {
    static let shared = CLIDetector()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    func detectCLITools(for bundleId: String, appPath: String) async -> [CLITool] {
        var tools: [CLITool] = []
        
        // Common CLI tool locations
        let searchPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/usr/bin",
            NSHomeDirectory() + "/.local/bin",
            NSHomeDirectory() + "/bin"
        ]
        
        // Also check app's own bin directory
        let appBinPath = (appPath as NSString).appendingPathComponent("Contents/Resources/bin")
        if fileManager.fileExists(atPath: appBinPath) {
            tools.append(contentsOf: await scanDirectory(appBinPath, bundleId: bundleId))
        }
        
        // Scan common locations for symlinks pointing to this app
        for searchPath in searchPaths {
            if fileManager.fileExists(atPath: searchPath) {
                tools.append(contentsOf: await scanDirectory(searchPath, bundleId: bundleId, appPath: appPath))
            }
        }
        
        return tools
    }
    
    private func scanDirectory(_ path: String, bundleId: String, appPath: String? = nil) async -> [CLITool] {
        var tools: [CLITool] = []
        
        guard let contents = try? fileManager.contentsOfDirectory(atPath: path) else {
            return tools
        }
        
        for item in contents {
            let itemPath = (path as NSString).appendingPathComponent(item)
            var isDirectory: ObjCBool = false
            
            guard fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory),
                  !isDirectory.boolValue else {
                continue
            }
            
            // Check if it's a symlink
            var isSymlink = false
            var symlinkTarget: String? = nil
            
            if let attributes = try? fileManager.attributesOfItem(atPath: itemPath),
               let type = attributes[.type] as? FileAttributeType,
               type == .typeSymbolicLink {
                isSymlink = true
                symlinkTarget = try? fileManager.destinationOfSymbolicLink(atPath: itemPath)
                
                // Check if symlink points to our app
                if let target = symlinkTarget, let appPath = appPath {
                    if target.contains(appPath) || target.contains(bundleId) {
                        // This tool is provided by our app
                    } else {
                        continue // Skip tools not related to this app
                    }
                }
            }
            
            // Get file size
            let size = getFileSize(at: itemPath)
            
            // Get last used date (approximate from modification date)
            let lastUsed = getLastUsedDate(at: itemPath)
            
            tools.append(CLITool(
                name: item,
                path: itemPath,
                size: size,
                isSymlink: isSymlink,
                symlinkTarget: symlinkTarget,
                associatedApp: bundleId,
                lastUsed: lastUsed
            ))
        }
        
        return tools
    }
    
    private func getFileSize(at path: String) -> Int64 {
        guard let attributes = try? fileManager.attributesOfItem(atPath: path),
              let size = attributes[.size] as? Int64 else {
            return 0
        }
        return size
    }
    
    private func getLastUsedDate(at path: String) -> Date? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: path),
              let modDate = attributes[.modificationDate] as? Date else {
            return nil
        }
        return modDate
    }
    
    func getAllCLITools() async -> [CLITool] {
        var allTools: [CLITool] = []
        
        let searchPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            NSHomeDirectory() + "/.local/bin"
        ]
        
        for path in searchPaths {
            if fileManager.fileExists(atPath: path) {
                allTools.append(contentsOf: await scanDirectory(path, bundleId: ""))
            }
        }
        
        return allTools
    }
}


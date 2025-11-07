//
//  FileSystemScanner.swift
//  CleanMyMac
//
//  Scans for leftover files and caches
//

import Foundation

class FileSystemScanner: ObservableObject {
    static let shared = FileSystemScanner()
    
    private let fileManager = FileManager.default
    
    func scanCacheDirectory(for bundleId: String) async -> [CacheLocation] {
        var cacheLocations: [CacheLocation] = []
        let cachePaths = [
            fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.path ?? "",
            NSHomeDirectory() + "/Library/Caches"
        ]
        
        for cachePath in cachePaths {
            guard !cachePath.isEmpty else { continue }
            
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: cachePath)
                
                for item in contents {
                    let itemPath = (cachePath as NSString).appendingPathComponent(item)
                    
                    // Check if this cache belongs to the app
                    if item.contains(bundleId) || item.lowercased().contains(bundleId.lowercased()) {
                        let (size, count) = await calculateDirectorySize(at: itemPath)
                        if size > 0 {
                            cacheLocations.append(CacheLocation(
                                appName: bundleId,
                                path: itemPath,
                                size: size,
                                fileCount: count
                            ))
                        }
                    }
                }
            } catch {
                // Permission denied or other error
                continue
            }
        }
        
        return cacheLocations
    }
    
    func scanLeftoverFiles(for bundleId: String) async -> [String] {
        var leftoverPaths: [String] = []
        let searchPaths = [
            NSHomeDirectory() + "/Library/Application Support",
            NSHomeDirectory() + "/Library/Preferences",
            NSHomeDirectory() + "/Library/Containers",
            NSHomeDirectory() + "/Library/Saved Application State"
        ]
        
        for searchPath in searchPaths {
            guard fileManager.fileExists(atPath: searchPath) else { continue }
            
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: searchPath)
                
                for item in contents {
                    if item.contains(bundleId) || item.lowercased().contains(bundleId.lowercased()) {
                        let itemPath = (searchPath as NSString).appendingPathComponent(item)
                        leftoverPaths.append(itemPath)
                    }
                }
            } catch {
                // Permission denied or other error
                continue
            }
        }
        
        return leftoverPaths
    }
    
    private func calculateDirectorySize(at path: String) async -> (Int64, Int) {
        var totalSize: Int64 = 0
        var fileCount = 0
        
        guard let enumerator = fileManager.enumerator(atPath: path) else {
            return (0, 0)
        }
        
        for case let file as String in enumerator {
            let filePath = (path as NSString).appendingPathComponent(file)
            
            do {
                let attributes = try fileManager.attributesOfItem(atPath: filePath)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                    fileCount += 1
                }
            } catch {
                continue
            }
        }
        
        return (totalSize, fileCount)
    }
    
    func deleteCache(at path: String) throws {
        try fileManager.removeItem(atPath: path)
    }
    
    func deleteLeftoverFile(at path: String) throws {
        try fileManager.removeItem(atPath: path)
    }
}


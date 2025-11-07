//
//  StorageAnalyzer.swift
//  CleanMyMac
//
//  Analyze disk storage
//

import Foundation

@MainActor
class StorageAnalyzer: ObservableObject {
    @Published var breakdown: StorageBreakdown?
    @Published var isLoading = false
    @Published var storageItems: [StorageItem] = []
    @Published var progressMessage: String = ""
    @Published var progressValue: Double = 0.0
    @Published var selectedDirectories: Set<String> = []
    
    private let fileManager = FileManager.default
    private var scanTask: Task<Void, Never>?
    
    // Available directories to scan
    let availableDirectories: [(path: String, name: String, category: StorageItem.StorageCategory)] = [
        (NSHomeDirectory() + "/Applications", "Applications", .applications),
        (NSHomeDirectory() + "/Documents", "Documents", .documents),
        (NSHomeDirectory() + "/Downloads", "Downloads", .downloads),
        (NSHomeDirectory() + "/Library/Caches", "Caches", .caches),
        (NSHomeDirectory() + "/Desktop", "Desktop", .documents),
        (NSHomeDirectory() + "/Movies", "Movies", .media),
        (NSHomeDirectory() + "/Music", "Music", .media),
        (NSHomeDirectory() + "/Pictures", "Pictures", .media),
        ("/Applications", "System Applications", .applications),
    ]
    
    init() {
        // Default: select user directories only (not system)
        // Don't check file existence here - that triggers permission dialogs
        let defaultPaths = availableDirectories.filter { 
            !$0.path.hasPrefix("/System") && 
            !$0.path.hasPrefix("/Library") && 
            $0.path.hasPrefix(NSHomeDirectory()) 
        }.map { $0.path }
        selectedDirectories = Set(defaultPaths)
    }
    
    func analyzeStorage() async {
        // Cancel any existing scan
        scanTask?.cancel()
        
        isLoading = true
        progressMessage = "Starting analysis..."
        progressValue = 0.0
        
        scanTask = Task {
            await performAnalysis()
        }
        
        await scanTask?.value
    }
    
    private func performAnalysis() async {
        defer {
            Task { @MainActor in
                isLoading = false
                progressMessage = ""
                progressValue = 0.0
            }
        }
        
        var items: [StorageItem] = []
        var byCategory: [StorageItem.StorageCategory: Int64] = [:]
        var byFileType: [StorageItem.FileType: Int64] = [:]
        var byLocation: [String: Int64] = [:]
        var totalSize: Int64 = 0
        
        // Use only selected directories
        let locations = availableDirectories.filter { selectedDirectories.contains($0.path) }
        
        guard !locations.isEmpty else {
            await MainActor.run {
                progressMessage = "No directories selected"
            }
            return
        }
        
        let totalLocations = locations.count
        var currentLocation = 0
        
        for location in locations {
            let path = location.path
            let category = location.category
            if Task.isCancelled { return }
            
            currentLocation += 1
            await MainActor.run {
                progressMessage = "Scanning \(location.name)..."
                progressValue = Double(currentLocation) / Double(totalLocations) * 0.8
            }
            
            // Check file existence in background to avoid permission dialogs on main thread
            let exists = await Task.detached {
                FileManager.default.fileExists(atPath: path)
            }.value
            
            if exists {
                let locationItems = await scanLocation(path, category: category)
                items.append(contentsOf: locationItems)
                
                let locationSize = locationItems.reduce(0) { $0 + $1.size }
                byLocation[path] = locationSize
                byCategory[category, default: 0] += locationSize
                totalSize += locationSize
            } else {
                await MainActor.run {
                    progressMessage = "Skipping \(location.name) (not accessible)"
                }
            }
            
            // Yield to prevent blocking
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        await MainActor.run {
            progressMessage = "Analyzing results..."
            progressValue = 0.85
        }
        
        // Analyze by file type
        for item in items {
            if Task.isCancelled { return }
            if let fileType = item.fileType {
                byFileType[fileType, default: 0] += item.size
            }
        }
        
        await MainActor.run {
            progressValue = 0.9
        }
        
        // Find large files (top 50)
        let largeFiles = items.filter { !$0.isDirectory }
            .sorted { $0.size > $1.size }
            .prefix(50)
            .map { $0 }
        
        // Find old files (not accessed in 90+ days)
        let oldFiles = items.filter { item in
            if let days = item.daysSinceAccessed {
                return days > 90
            }
            return false
        }
        
        // Find empty folders
        let emptyFolders = items.filter { $0.isDirectory && $0.fileCount == 0 }
        
        await MainActor.run {
            progressValue = 1.0
            storageItems = items
            breakdown = StorageBreakdown(
                totalSize: totalSize,
                byCategory: byCategory,
                byFileType: byFileType,
                byLocation: byLocation,
                largeFiles: Array(largeFiles),
                oldFiles: oldFiles,
                emptyFolders: emptyFolders
            )
        }
    }
    
    func cancelScan() {
        scanTask?.cancel()
        isLoading = false
        progressMessage = ""
        progressValue = 0.0
    }
    
    private func scanLocation(_ path: String, category: StorageItem.StorageCategory) async -> [StorageItem] {
        return await withTaskGroup(of: [StorageItem].self) { group in
            var allItems: [StorageItem] = []
            
            // Run scanning on background thread
            group.addTask {
                await Task.detached(priority: .userInitiated) {
                    var items: [StorageItem] = []
                    let fileManager = FileManager.default
                    
                    guard let enumerator = fileManager.enumerator(atPath: path) else {
                        return items
                    }
                    
                    var fileCount = 0
                    var batch: [StorageItem] = []
                    
                    for case let file as String in enumerator {
                        // Check for cancellation
                        if Task.isCancelled {
                            return items
                        }
                        
                        let filePath = (path as NSString).appendingPathComponent(file)
                        var isDirectory: ObjCBool = false
                        
                        guard fileManager.fileExists(atPath: filePath, isDirectory: &isDirectory) else {
                            continue
                        }
                        
                        // Get file attributes
                        guard let attributes = try? fileManager.attributesOfItem(atPath: filePath) else {
                            continue
                        }
                        
                        let size = attributes[.size] as? Int64 ?? 0
                        let lastAccessed = attributes[.modificationDate] as? Date
                        
                        // Determine file type (static function to avoid actor isolation)
                        let fileType = StorageAnalyzer.detectFileTypeStatic(filePath: filePath)
                        
                        // Count files if directory (simplified - don't recurse)
                        var dirFileCount = 0
                        if isDirectory.boolValue {
                            if let contents = try? fileManager.contentsOfDirectory(atPath: filePath) {
                                dirFileCount = contents.count
                            }
                        }
                        
                        let item = StorageItem(
                            name: (file as NSString).lastPathComponent,
                            path: filePath,
                            size: size,
                            isDirectory: isDirectory.boolValue,
                            category: category,
                            fileType: fileType,
                            lastAccessed: lastAccessed,
                            fileCount: dirFileCount
                        )
                        
                        batch.append(item)
                        fileCount += 1
                        
                        // Yield every 100 files to prevent blocking
                        if fileCount % 100 == 0 {
                            items.append(contentsOf: batch)
                            batch.removeAll()
                            try? await Task.sleep(nanoseconds: 1_000_000) // 1ms yield
                        }
                    }
                    
                    items.append(contentsOf: batch)
                    return items
                }.value
            }
            
            for await locationItems in group {
                allItems.append(contentsOf: locationItems)
            }
            
            return allItems
        }
    }
    
    nonisolated private static func detectFileTypeStatic(filePath: String) -> StorageItem.FileType? {
        let ext = (filePath as NSString).pathExtension.lowercased()
        
        let imageExts = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp", "svg"]
        let videoExts = ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v"]
        let audioExts = ["mp3", "wav", "aac", "flac", "m4a", "ogg", "wma"]
        let docExts = ["pdf", "doc", "docx", "txt", "rtf", "pages", "key", "numbers"]
        let archiveExts = ["zip", "rar", "7z", "tar", "gz", "bz2", "dmg", "iso"]
        let codeExts = ["swift", "js", "ts", "py", "java", "cpp", "c", "h", "html", "css", "json", "xml"]
        let dbExts = ["db", "sqlite", "sqlite3", "realm"]
        let logExts = ["log", "txt"]
        
        if imageExts.contains(ext) { return .image }
        if videoExts.contains(ext) { return .video }
        if audioExts.contains(ext) { return .audio }
        if docExts.contains(ext) { return .document }
        if archiveExts.contains(ext) { return .archive }
        if codeExts.contains(ext) { return .code }
        if dbExts.contains(ext) { return .database }
        if logExts.contains(ext) { return .log }
        
        return nil
    }
    
    
    func findDuplicates() async -> [[StorageItem]] {
        var duplicates: [String: [StorageItem]] = [:]
        
        // Group files by size and name (simplified - full implementation would use hash)
        for item in storageItems where !item.isDirectory {
            let key = "\(item.name)_\(item.size)"
            duplicates[key, default: []].append(item)
        }
        
        // Return only groups with 2+ items
        return duplicates.values.filter { $0.count > 1 }
    }
}


//
//  StorageItem.swift
//  CleanMyMac
//
//  File/folder storage information
//

import Foundation

struct StorageItem: Identifiable, Codable {
    let id: String
    let name: String
    let path: String
    let size: Int64
    let isDirectory: Bool
    let category: StorageCategory
    let fileType: FileType?
    let lastAccessed: Date?
    let fileCount: Int
    
    enum StorageCategory: String, Codable {
        case applications = "Applications"
        case documents = "Documents"
        case system = "System"
        case caches = "Caches"
        case downloads = "Downloads"
        case media = "Media"
        case libraries = "Libraries"
        case other = "Other"
    }
    
    enum FileType: String, Codable {
        case image = "Images"
        case video = "Videos"
        case audio = "Audio"
        case document = "Documents"
        case archive = "Archives"
        case code = "Code"
        case database = "Databases"
        case log = "Logs"
        case other = "Other"
    }
    
    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedLastAccessed: String? {
        guard let date = lastAccessed else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var daysSinceAccessed: Int? {
        guard let date = lastAccessed else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         path: String,
         size: Int64,
         isDirectory: Bool,
         category: StorageCategory,
         fileType: FileType? = nil,
         lastAccessed: Date? = nil,
         fileCount: Int = 0) {
        self.id = id
        self.name = name
        self.path = path
        self.size = size
        self.isDirectory = isDirectory
        self.category = category
        self.fileType = fileType
        self.lastAccessed = lastAccessed
        self.fileCount = fileCount
    }
}

struct StorageBreakdown: Codable {
    let totalSize: Int64
    let byCategory: [StorageItem.StorageCategory: Int64]
    let byFileType: [StorageItem.FileType: Int64]
    let byLocation: [String: Int64]
    let largeFiles: [StorageItem]
    let oldFiles: [StorageItem]
    let emptyFolders: [StorageItem]
    
    var displayTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    init(totalSize: Int64 = 0,
         byCategory: [StorageItem.StorageCategory: Int64] = [:],
         byFileType: [StorageItem.FileType: Int64] = [:],
         byLocation: [String: Int64] = [:],
         largeFiles: [StorageItem] = [],
         oldFiles: [StorageItem] = [],
         emptyFolders: [StorageItem] = []) {
        self.totalSize = totalSize
        self.byCategory = byCategory
        self.byFileType = byFileType
        self.byLocation = byLocation
        self.largeFiles = largeFiles
        self.oldFiles = oldFiles
        self.emptyFolders = emptyFolders
    }
}


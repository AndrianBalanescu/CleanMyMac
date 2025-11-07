//
//  CacheLocation.swift
//  CleanMyMac
//
//  Data model for cache file locations
//

import Foundation

struct CacheLocation: Identifiable, Codable {
    let id: String
    let appName: String
    let path: String
    let size: Int64
    let fileCount: Int
    
    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    init(id: String = UUID().uuidString,
         appName: String,
         path: String,
         size: Int64,
         fileCount: Int) {
        self.id = id
        self.appName = appName
        self.path = path
        self.size = size
        self.fileCount = fileCount
    }
}


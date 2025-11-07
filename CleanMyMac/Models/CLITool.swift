//
//  CLITool.swift
//  CleanMyMac
//
//  CLI tool information
//

import Foundation

struct CLITool: Identifiable, Codable {
    let id: String
    let name: String
    let path: String
    let size: Int64
    let isSymlink: Bool
    let symlinkTarget: String?
    let associatedApp: String? // Bundle ID of app that provides this tool
    let lastUsed: Date?
    
    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedLastUsed: String? {
        guard let date = lastUsed else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         path: String,
         size: Int64,
         isSymlink: Bool = false,
         symlinkTarget: String? = nil,
         associatedApp: String? = nil,
         lastUsed: Date? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.size = size
        self.isSymlink = isSymlink
        self.symlinkTarget = symlinkTarget
        self.associatedApp = associatedApp
        self.lastUsed = lastUsed
    }
}


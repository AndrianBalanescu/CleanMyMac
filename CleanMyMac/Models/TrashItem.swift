//
//  TrashItem.swift
//  CleanMyMac
//
//  Data model for trash files
//

import Foundation

struct TrashItem: Identifiable, Codable {
    let id: String
    let name: String
    let path: String
    let size: Int64
    let dateDeleted: Date
    let isDirectory: Bool
    
    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateDeleted)
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         path: String,
         size: Int64,
         dateDeleted: Date,
         isDirectory: Bool) {
        self.id = id
        self.name = name
        self.path = path
        self.size = size
        self.dateDeleted = dateDeleted
        self.isDirectory = isDirectory
    }
}


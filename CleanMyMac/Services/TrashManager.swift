//
//  TrashManager.swift
//  CleanMyMac
//
//  Manages trash file operations
//

import Foundation

@MainActor
class TrashManager: ObservableObject {
    @Published var trashItems: [TrashItem] = []
    @Published var isLoading = false
    @Published var totalSize: Int64 = 0
    
    private let fileManager = FileManager.default
    
    func scanTrash() async {
        isLoading = true
        defer { isLoading = false }
        
        var items: [TrashItem] = []
        var total: Int64 = 0
        
        // User trash
        if let userTrash = try? fileManager.url(for: .trashDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            items.append(contentsOf: await scanTrashDirectory(at: userTrash.path))
        }
        
        // Calculate total size
        for item in items {
            total += item.size
        }
        
        trashItems = items.sorted { $0.dateDeleted > $1.dateDeleted }
        totalSize = total
    }
    
    private func scanTrashDirectory(at path: String) async -> [TrashItem] {
        var items: [TrashItem] = []
        
        guard let contents = try? fileManager.contentsOfDirectory(atPath: path) else {
            return items
        }
        
        for item in contents {
            let itemPath = (path as NSString).appendingPathComponent(item)
            var isDirectory: ObjCBool = false
            
            guard fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory) else {
                continue
            }
            
            do {
                let attributes = try fileManager.attributesOfItem(atPath: itemPath)
                let size = attributes[.size] as? Int64 ?? 0
                let dateDeleted = attributes[.modificationDate] as? Date ?? Date()
                
                // If it's a directory, calculate total size
                let finalSize = isDirectory.boolValue ? await calculateDirectorySize(at: itemPath) : size
                
                items.append(TrashItem(
                    name: item,
                    path: itemPath,
                    size: finalSize,
                    dateDeleted: dateDeleted,
                    isDirectory: isDirectory.boolValue
                ))
            } catch {
                continue
            }
        }
        
        return items
    }
    
    private func calculateDirectorySize(at path: String) async -> Int64 {
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
    
    func emptyTrash() async throws {
        for item in trashItems {
            try? fileManager.removeItem(atPath: item.path)
        }
        
        trashItems = []
        totalSize = 0
    }
    
    func deleteItem(_ item: TrashItem) throws {
        try fileManager.removeItem(atPath: item.path)
        trashItems.removeAll { $0.id == item.id }
        totalSize -= item.size
    }
    
    var displayTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}


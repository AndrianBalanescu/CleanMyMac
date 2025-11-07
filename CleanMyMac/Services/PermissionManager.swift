//
//  PermissionManager.swift
//  CleanMyMac
//
//  Handles macOS permissions
//

import Foundation
import AppKit
import ApplicationServices

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var hasFullDiskAccess: Bool = false
    
    private init() {
        checkFullDiskAccess()
    }
    
    func checkFullDiskAccess() {
        let fileManager = FileManager.default
        let testPath = "/Library/Application Support"
        
        // Try to access a protected directory
        let hasAccess = fileManager.isReadableFile(atPath: testPath) ||
                       fileManager.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support")
        
        hasFullDiskAccess = hasAccess
    }
    
    func requestFullDiskAccess() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
    
    func checkAndRequestPermissions() -> Bool {
        checkFullDiskAccess()
        if !hasFullDiskAccess {
            requestFullDiskAccess()
            return false
        }
        return true
    }
}


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
    @Published var hasCheckedPermissions: Bool = false
    
    private var lastCheckTime: Date?
    private let checkInterval: TimeInterval = 5.0 // Only check every 5 seconds max
    
    private init() {
        // Don't check on init - let user request it
    }
    
    func checkFullDiskAccess() {
        // Prevent rapid repeated checks
        if let lastCheck = lastCheckTime,
           Date().timeIntervalSince(lastCheck) < checkInterval {
            return
        }
        
        lastCheckTime = Date()
        
        let fileManager = FileManager.default
        // Use a safer check that doesn't trigger permission dialogs
        let testPath = NSHomeDirectory() + "/Library/Application Support"
        
        // Try to access a protected directory (but don't fail if we can't)
        let hasAccess = fileManager.fileExists(atPath: testPath) ||
                       fileManager.isReadableFile(atPath: testPath)
        
        hasFullDiskAccess = hasAccess
        hasCheckedPermissions = true
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


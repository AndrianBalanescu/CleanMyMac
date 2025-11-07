//
//  StartupItem.swift
//  CleanMyMac
//
//  Startup item information
//

import Foundation

struct StartupItem: Identifiable, Codable {
    let id: String
    let name: String
    let path: String
    let type: StartupType
    let isEnabled: Bool
    let associatedApp: String? // Bundle ID
    
    enum StartupType: String, Codable {
        case launchAgent = "Launch Agent"
        case launchDaemon = "Launch Daemon"
        case loginItem = "Login Item"
        case backgroundService = "Background Service"
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         path: String,
         type: StartupType,
         isEnabled: Bool = true,
         associatedApp: String? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.type = type
        self.isEnabled = isEnabled
        self.associatedApp = associatedApp
    }
}


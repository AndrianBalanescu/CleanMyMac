//
//  AppMetadata.swift
//  CleanMyMac
//
//  Extended app metadata information
//

import Foundation

struct AppMetadata: Codable {
    let installationDate: Date?
    let lastUsedDate: Date?
    let launchCount: Int
    let category: AppCategory?
    let developer: String?
    let copyright: String?
    let isAppStoreApp: Bool
    let updateAvailable: Bool
    let permissions: [String]
    let backgroundProcesses: [String]
    
    enum AppCategory: String, Codable {
        case developer = "Developer Tools"
        case productivity = "Productivity"
        case entertainment = "Entertainment"
        case utilities = "Utilities"
        case graphics = "Graphics & Design"
        case music = "Music"
        case video = "Video"
        case education = "Education"
        case business = "Business"
        case finance = "Finance"
        case games = "Games"
        case social = "Social Networking"
        case other = "Other"
    }
    
    init(installationDate: Date? = nil,
         lastUsedDate: Date? = nil,
         launchCount: Int = 0,
         category: AppCategory? = nil,
         developer: String? = nil,
         copyright: String? = nil,
         isAppStoreApp: Bool = false,
         updateAvailable: Bool = false,
         permissions: [String] = [],
         backgroundProcesses: [String] = []) {
        self.installationDate = installationDate
        self.lastUsedDate = lastUsedDate
        self.launchCount = launchCount
        self.category = category
        self.developer = developer
        self.copyright = copyright
        self.isAppStoreApp = isAppStoreApp
        self.updateAvailable = updateAvailable
        self.permissions = permissions
        self.backgroundProcesses = backgroundProcesses
    }
    
    var formattedInstallationDate: String? {
        guard let date = installationDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var formattedLastUsedDate: String? {
        guard let date = lastUsedDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var daysSinceLastUsed: Int? {
        guard let date = lastUsedDate else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day
    }
}


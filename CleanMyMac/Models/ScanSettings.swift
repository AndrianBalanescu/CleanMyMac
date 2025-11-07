//
//  ScanSettings.swift
//  CleanMyMac
//
//  User preferences for what to scan
//

import Foundation

class ScanSettings: ObservableObject {
    static let shared = ScanSettings()
    
    @Published var scanApplications: Bool = false
    @Published var scanStorage: Bool = false
    @Published var scanSystemMetrics: Bool = false
    @Published var scanNetwork: Bool = false
    @Published var scanTrash: Bool = false
    @Published var autoStartMonitoring: Bool = false
    
    @Published var allowedFolders: Set<String> = []
    @Published var requireFullDiskAccess: Bool = false
    
    private let defaults = UserDefaults.standard
    private let scanApplicationsKey = "scanApplications"
    private let scanStorageKey = "scanStorage"
    private let autoStartKey = "autoStartMonitoring"
    
    private init() {
        loadSettings()
    }
    
    func loadSettings() {
        scanApplications = defaults.bool(forKey: scanApplicationsKey)
        scanStorage = defaults.bool(forKey: scanStorageKey)
        autoStartMonitoring = defaults.bool(forKey: autoStartKey)
    }
    
    func saveSettings() {
        defaults.set(scanApplications, forKey: scanApplicationsKey)
        defaults.set(scanStorage, forKey: scanStorageKey)
        defaults.set(autoStartMonitoring, forKey: autoStartKey)
    }
}


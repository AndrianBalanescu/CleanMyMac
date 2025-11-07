//
//  ProcessInfo.swift
//  CleanMyMac
//
//  Process information
//

import Foundation

struct ProcessInfo: Identifiable, Codable {
    let id: Int32 // PID
    let name: String
    let bundleIdentifier: String?
    let cpuUsage: Double
    let memoryUsage: Int64
    let threadCount: Int
    let isUserProcess: Bool
    let parentPID: Int32?
    let startTime: Date?
    
    var displayMemoryUsage: String {
        ByteCountFormatter.string(fromByteCount: memoryUsage, countStyle: .memory)
    }
    
    init(id: Int32,
         name: String,
         bundleIdentifier: String? = nil,
         cpuUsage: Double = 0,
         memoryUsage: Int64 = 0,
         threadCount: Int = 0,
         isUserProcess: Bool = true,
         parentPID: Int32? = nil,
         startTime: Date? = nil) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.threadCount = threadCount
        self.isUserProcess = isUserProcess
        self.parentPID = parentPID
        self.startTime = startTime
    }
}


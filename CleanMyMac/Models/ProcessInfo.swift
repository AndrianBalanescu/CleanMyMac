//
//  ProcessInfo.swift
//  CleanMyMac
//
//  Process information
//

import Foundation
import AppKit

enum ProcessState: String, Codable {
    case running = "Running"
    case sleeping = "Sleeping"
    case zombie = "Zombie"
    case stopped = "Stopped"
    case idle = "Idle"
    case unknown = "Unknown"
}

enum ActivationPolicy: String, Codable {
    case regular = "Regular"
    case accessory = "Accessory"
    case prohibited = "Prohibited"
    case unknown = "Unknown"
}

struct ProcessInfo: Identifiable, Codable {
    // Basic Info
    let id: Int32 // PID
    let name: String
    let bundleIdentifier: String?
    let executablePath: String?
    let workingDirectory: String?
    let commandLine: [String]?
    let environment: [String: String]?
    
    // Resource Usage
    let cpuUsage: Double
    let cpuTimeUser: Double // User CPU time in seconds
    let cpuTimeSystem: Double // System CPU time in seconds
    let memoryUsage: Int64 // Resident memory (RSS)
    let virtualMemorySize: Int64 // Virtual memory size
    let sharedMemorySize: Int64 // Shared memory
    let threadCount: Int
    let fileDescriptorCount: Int?
    
    // Process Details
    let state: ProcessState
    let priority: Int32?
    let niceValue: Int32?
    let realUID: UInt32?
    let effectiveUID: UInt32?
    let realGID: UInt32?
    let effectiveGID: UInt32?
    let processGroupID: Int32?
    let sessionID: Int32?
    let parentPID: Int32?
    let startTime: Date?
    let launchDate: Date?
    
    // System Info
    let isUserProcess: Bool
    let pageFaults: Int64?
    let pageIns: Int64?
    let pageOuts: Int64?
    
    // AppKit/NSRunningApplication Info
    let activationPolicy: ActivationPolicy?
    let processSerialNumber: Int64?
    let isFinishedLaunching: Bool?
    let isHidden: Bool?
    let ownsMenuBar: Bool?
    let icon: Data? // NSImage as Data
    
    // I/O Statistics
    let bytesRead: Int64?
    let bytesWritten: Int64?
    let diskReadBytes: Int64?
    let diskWriteBytes: Int64?
    
    // Network
    let networkConnectionsCount: Int?
    
    // Additional Metrics
    let energyImpact: Double?
    let gpuUsage: Double?
    
    // Computed Properties
    var displayMemoryUsage: String {
        ByteCountFormatter.string(fromByteCount: memoryUsage, countStyle: .memory)
    }
    
    var displayVirtualMemory: String {
        ByteCountFormatter.string(fromByteCount: virtualMemorySize, countStyle: .memory)
    }
    
    var displaySharedMemory: String {
        ByteCountFormatter.string(fromByteCount: sharedMemorySize, countStyle: .memory)
    }
    
    var displayCPUTime: String {
        let total = cpuTimeUser + cpuTimeSystem
        return String(format: "%.2fs (user: %.2fs, system: %.2fs)", total, cpuTimeUser, cpuTimeSystem)
    }
    
    var uptime: TimeInterval? {
        guard let startTime = startTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }
    
    var displayUptime: String {
        guard let uptime = uptime else { return "Unknown" }
        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        let seconds = Int(uptime) % 60
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    init(id: Int32,
         name: String,
         bundleIdentifier: String? = nil,
         executablePath: String? = nil,
         workingDirectory: String? = nil,
         commandLine: [String]? = nil,
         environment: [String: String]? = nil,
         cpuUsage: Double = 0,
         cpuTimeUser: Double = 0,
         cpuTimeSystem: Double = 0,
         memoryUsage: Int64 = 0,
         virtualMemorySize: Int64 = 0,
         sharedMemorySize: Int64 = 0,
         threadCount: Int = 0,
         fileDescriptorCount: Int? = nil,
         state: ProcessState = .unknown,
         priority: Int32? = nil,
         niceValue: Int32? = nil,
         realUID: UInt32? = nil,
         effectiveUID: UInt32? = nil,
         realGID: UInt32? = nil,
         effectiveGID: UInt32? = nil,
         processGroupID: Int32? = nil,
         sessionID: Int32? = nil,
         parentPID: Int32? = nil,
         startTime: Date? = nil,
         launchDate: Date? = nil,
         isUserProcess: Bool = true,
         pageFaults: Int64? = nil,
         pageIns: Int64? = nil,
         pageOuts: Int64? = nil,
         activationPolicy: ActivationPolicy? = nil,
         processSerialNumber: Int64? = nil,
         isFinishedLaunching: Bool? = nil,
         isHidden: Bool? = nil,
         ownsMenuBar: Bool? = nil,
         icon: Data? = nil,
         bytesRead: Int64? = nil,
         bytesWritten: Int64? = nil,
         diskReadBytes: Int64? = nil,
         diskWriteBytes: Int64? = nil,
         networkConnectionsCount: Int? = nil,
         energyImpact: Double? = nil,
         gpuUsage: Double? = nil) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.executablePath = executablePath
        self.workingDirectory = workingDirectory
        self.commandLine = commandLine
        self.environment = environment
        self.cpuUsage = cpuUsage
        self.cpuTimeUser = cpuTimeUser
        self.cpuTimeSystem = cpuTimeSystem
        self.memoryUsage = memoryUsage
        self.virtualMemorySize = virtualMemorySize
        self.sharedMemorySize = sharedMemorySize
        self.threadCount = threadCount
        self.fileDescriptorCount = fileDescriptorCount
        self.state = state
        self.priority = priority
        self.niceValue = niceValue
        self.realUID = realUID
        self.effectiveUID = effectiveUID
        self.realGID = realGID
        self.effectiveGID = effectiveGID
        self.processGroupID = processGroupID
        self.sessionID = sessionID
        self.parentPID = parentPID
        self.startTime = startTime
        self.launchDate = launchDate
        self.isUserProcess = isUserProcess
        self.pageFaults = pageFaults
        self.pageIns = pageIns
        self.pageOuts = pageOuts
        self.activationPolicy = activationPolicy
        self.processSerialNumber = processSerialNumber
        self.isFinishedLaunching = isFinishedLaunching
        self.isHidden = isHidden
        self.ownsMenuBar = ownsMenuBar
        self.icon = icon
        self.bytesRead = bytesRead
        self.bytesWritten = bytesWritten
        self.diskReadBytes = diskReadBytes
        self.diskWriteBytes = diskWriteBytes
        self.networkConnectionsCount = networkConnectionsCount
        self.energyImpact = energyImpact
        self.gpuUsage = gpuUsage
    }
}


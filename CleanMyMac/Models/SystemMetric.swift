//
//  SystemMetric.swift
//  CleanMyMac
//
//  System performance metrics
//

import Foundation

struct SystemMetric: Identifiable, Codable {
    let id: String
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Double
    let memoryTotal: Int64
    let memoryUsed: Int64
    let diskReadBytes: Int64
    let diskWriteBytes: Int64
    let networkInBytes: Int64
    let networkOutBytes: Int64
    
    var memoryUsagePercent: Double {
        guard memoryTotal > 0 else { return 0 }
        return Double(memoryUsed) / Double(memoryTotal) * 100
    }
    
    var displayMemoryTotal: String {
        ByteCountFormatter.string(fromByteCount: memoryTotal, countStyle: .memory)
    }
    
    var displayMemoryUsed: String {
        ByteCountFormatter.string(fromByteCount: memoryUsed, countStyle: .memory)
    }
    
    init(id: String = UUID().uuidString,
         timestamp: Date = Date(),
         cpuUsage: Double = 0,
         memoryUsage: Double = 0,
         memoryTotal: Int64 = 0,
         memoryUsed: Int64 = 0,
         diskReadBytes: Int64 = 0,
         diskWriteBytes: Int64 = 0,
         networkInBytes: Int64 = 0,
         networkOutBytes: Int64 = 0) {
        self.id = id
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.memoryTotal = memoryTotal
        self.memoryUsed = memoryUsed
        self.diskReadBytes = diskReadBytes
        self.diskWriteBytes = diskWriteBytes
        self.networkInBytes = networkInBytes
        self.networkOutBytes = networkOutBytes
    }
}


//
//  SystemMonitor.swift
//  CleanMyMac
//
//  Monitor system performance
//

import Foundation
import IOKit

@MainActor
class SystemMonitor: ObservableObject {
    @Published var currentMetric: SystemMetric?
    @Published var metricsHistory: [SystemMetric] = []
    @Published var isMonitoring = false
    
    private var monitoringTask: Task<Void, Never>?
    private let maxHistoryCount = 100
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitoringTask = Task {
            while !Task.isCancelled && isMonitoring {
                let metric = await collectMetrics()
                currentMetric = metric
                
                metricsHistory.append(metric)
                if metricsHistory.count > maxHistoryCount {
                    metricsHistory.removeFirst()
                }
                
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    private func collectMetrics() async -> SystemMetric {
        // CPU Usage
        let cpuUsage = await getCPUUsage()
        
        // Memory Usage
        let (memoryTotal, memoryUsed) = await getMemoryInfo()
        
        // Disk I/O (simplified - would need more complex implementation)
        let (diskRead, diskWrite) = await getDiskIO()
        
        // Network I/O (simplified)
        let (networkIn, networkOut) = await getNetworkIO()
        
        return SystemMetric(
            cpuUsage: cpuUsage,
            memoryUsage: Double(memoryUsed) / Double(memoryTotal) * 100,
            memoryTotal: memoryTotal,
            memoryUsed: memoryUsed,
            diskReadBytes: diskRead,
            diskWriteBytes: diskWrite,
            networkInBytes: networkIn,
            networkOutBytes: networkOut
        )
    }
    
    private func getCPUUsage() async -> Double {
        // Use top command or system calls
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/top")
        process.arguments = ["-l", "1", "-n", "0"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            // Parse CPU usage from top output
            if let cpuLine = output.components(separatedBy: "\n").first(where: { $0.contains("CPU usage") }) {
                // Extract percentage (simplified parsing)
                let components = cpuLine.components(separatedBy: " ")
                for component in components {
                    if component.hasSuffix("%") {
                        let value = Double(component.replacingOccurrences(of: "%", with: "")) ?? 0
                        return value
                    }
                }
            }
        } catch {
            // Fallback
        }
        
        return 0
    }
    
    private func getMemoryInfo() async -> (Int64, Int64) {
        var totalMemory: Int64 = 0
        var usedMemory: Int64 = 0
        
        // Use vm_stat for memory info
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/vm_stat")
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            // Parse memory info (simplified)
            // In production, would parse vm_stat output properly
            // For now, use ProcessInfo
            let pageSize = Int64(vm_kernel_page_size)
            
            // Get total physical memory
            var size = MemoryLayout<Int64>.size
            sysctlbyname("hw.memsize", &totalMemory, &size, nil, 0)
            
            // Approximate used memory (would need proper calculation)
            usedMemory = totalMemory / 2 // Placeholder
        } catch {
            // Fallback
        }
        
        return (totalMemory, usedMemory)
    }
    
    private func getDiskIO() async -> (Int64, Int64) {
        // Simplified - would need iostat or similar
        return (0, 0)
    }
    
    private func getNetworkIO() async -> (Int64, Int64) {
        // Simplified - would need netstat or similar
        return (0, 0)
    }
}


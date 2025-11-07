//
//  ProcessManager.swift
//  CleanMyMac
//
//  Manage running processes
//

import Foundation
import AppKit

@MainActor
class ProcessManager: ObservableObject {
    @Published var processes: [ProcessInfo] = []
    @Published var isLoading = false
    
    func refreshProcesses() async {
        isLoading = true
        defer { isLoading = false }
        
        var processList: [ProcessInfo] = []
        
        // Get running applications
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            if let bundleId = app.bundleIdentifier,
               let pid = app.processIdentifier as Int32? {
                
                let processInfo = ProcessInfo(
                    id: pid,
                    name: app.localizedName ?? "Unknown",
                    bundleIdentifier: bundleId,
                    cpuUsage: 0, // Would need to get from system
                    memoryUsage: 0, // Will be populated from system processes
                    threadCount: 0,
                    isUserProcess: true,
                    startTime: nil
                )
                
                processList.append(processInfo)
            }
        }
        
        // Get system processes (simplified - would use ps command)
        let systemProcesses = await getSystemProcesses()
        processList.append(contentsOf: systemProcesses)
        
        processes = processList.sorted { $0.memoryUsage > $1.memoryUsage }
    }
    
    private func getSystemProcesses() async -> [ProcessInfo] {
        var processes: [ProcessInfo] = []
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-ax", "-o", "pid,comm,%cpu,rss"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let lines = output.components(separatedBy: "\n")
            for line in lines.dropFirst() { // Skip header
                let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                
                if components.count >= 4,
                   let pid = Int32(components[0]),
                   let cpu = Double(components[2]),
                   let memory = Int64(components[3]) {
                    
                    let processInfo = ProcessInfo(
                        id: pid,
                        name: components[1],
                        cpuUsage: cpu,
                        memoryUsage: memory * 1024, // Convert from KB to bytes
                        isUserProcess: pid > 100 // Simplified check
                    )
                    
                    processes.append(processInfo)
                }
            }
        } catch {
            // Error handling
        }
        
        return processes
    }
    
    func killProcess(_ processInfo: ProcessInfo) throws {
        let killProcess = Process()
        killProcess.executableURL = URL(fileURLWithPath: "/bin/kill")
        killProcess.arguments = ["-9", "\(processInfo.id)"]
        
        try killProcess.run()
        killProcess.waitUntilExit()
        
        // Remove from list
        processes.removeAll { $0.id == processInfo.id }
    }
}


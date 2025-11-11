//
//  ProcessManager.swift
//  CleanMyMac
//
//  Manage running processes
//

import Foundation
import AppKit

enum ProcessFilter: String, CaseIterable {
    case all = "All"
    case user = "User"
    case system = "System"
    case applications = "Applications"
}

enum ProcessSortOption: String, CaseIterable {
    case cpu = "CPU"
    case memory = "Memory"
    case name = "Name"
    case pid = "PID"
    case threads = "Threads"
}

@MainActor
class ProcessManager: ObservableObject {
    @Published var processes: [ProcessInfo] = []
    @Published var filteredProcesses: [ProcessInfo] = []
    @Published var isLoading = false
    @Published var isMonitoring = false
    @Published var refreshInterval: TimeInterval = 2.0
    
    // Filtering and sorting
    @Published var searchText: String = ""
    @Published var currentFilter: ProcessFilter = .all
    @Published var currentSort: ProcessSortOption = .memory
    @Published var sortAscending: Bool = false
    
    // Grouping
    @Published var groupByParent: Bool = false
    @Published var groupByUser: Bool = false
    @Published var groupByBundle: Bool = false
    
    private var monitoringTask: Task<Void, Never>?
    private let processInfoService = ProcessInfoService.shared
    private var cpuUsageCache: [Int32: (time: timeval, ticks: UInt64)] = [:]
    private var networkMonitor: NetworkMonitor?
    
    init() {
        // Initialize network monitor for connection counting
        networkMonitor = NetworkMonitor()
    }
    
    // MARK: - Process Refresh
    
    func refreshProcesses() async {
        isLoading = true
        defer { isLoading = false }
        
        // Get all PIDs
        let pids = processInfoService.getAllProcessPIDs()
        
        // Limit to prevent UI freeze - start with fewer processes
        let maxProcesses = 200
        let limitedPids = Array(pids.prefix(maxProcesses))
        
        var processList: [ProcessInfo] = []
        
        // Process in batches - limit concurrency to avoid overwhelming the system
        let batchSize = 50
        for batchStart in stride(from: 0, to: limitedPids.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, limitedPids.count)
            let batch = Array(limitedPids[batchStart..<batchEnd])
            
            await withTaskGroup(of: ProcessInfo?.self) { group in
                for pid in batch {
                    group.addTask {
                        await self.processInfoService.getDetailedProcessInfo(pid: pid)
                    }
                }
                
                // Collect results from this batch
                for await processInfo in group {
                    if let info = processInfo {
                        processList.append(info)
                    }
                }
            }
            
            // Update UI after each batch
            await MainActor.run {
                self.processes = processList
                self.applyFiltersAndSort()
            }
        }
        
        // Update network connection counts (skip if it takes too long)
        let networkTask = Task {
            await updateNetworkConnectionCounts(&processList)
        }
        
        // Wait max 2 seconds for network scan
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        networkTask.cancel()
        
        // Final update
        processes = processList
        applyFiltersAndSort()
    }
    
    private func updateNetworkConnectionCounts(_ processList: inout [ProcessInfo]) async {
        guard let networkMonitor = networkMonitor else { return }
        await networkMonitor.scanConnections()
        
        // Count connections per PID (simplified - would need lsof for accurate mapping)
        var connectionCounts: [Int32: Int] = [:]
        for connection in networkMonitor.connections {
            connectionCounts[connection.processPID, default: 0] += 1
        }
        
        // Update process list with connection counts
        for i in 0..<processList.count {
            let pid = processList[i].id
            if let count = connectionCounts[pid] {
                let current = processList[i]
                processList[i] = ProcessInfo(
                    id: current.id,
                    name: current.name,
                    bundleIdentifier: current.bundleIdentifier,
                    executablePath: current.executablePath,
                    workingDirectory: current.workingDirectory,
                    commandLine: current.commandLine,
                    environment: current.environment,
                    cpuUsage: current.cpuUsage,
                    cpuTimeUser: current.cpuTimeUser,
                    cpuTimeSystem: current.cpuTimeSystem,
                    memoryUsage: current.memoryUsage,
                    virtualMemorySize: current.virtualMemorySize,
                    sharedMemorySize: current.sharedMemorySize,
                    threadCount: current.threadCount,
                    fileDescriptorCount: current.fileDescriptorCount,
                    state: current.state,
                    priority: current.priority,
                    niceValue: current.niceValue,
                    realUID: current.realUID,
                    effectiveUID: current.effectiveUID,
                    realGID: current.realGID,
                    effectiveGID: current.effectiveGID,
                    processGroupID: current.processGroupID,
                    sessionID: current.sessionID,
                    parentPID: current.parentPID,
                    startTime: current.startTime,
                    launchDate: current.launchDate,
                    isUserProcess: current.isUserProcess,
                    pageFaults: current.pageFaults,
                    pageIns: current.pageIns,
                    pageOuts: current.pageOuts,
                    activationPolicy: current.activationPolicy,
                    processSerialNumber: current.processSerialNumber,
                    isFinishedLaunching: current.isFinishedLaunching,
                    isHidden: current.isHidden,
                    ownsMenuBar: current.ownsMenuBar,
                    icon: current.icon,
                    bytesRead: current.bytesRead,
                    bytesWritten: current.bytesWritten,
                    diskReadBytes: current.diskReadBytes,
                    diskWriteBytes: current.diskWriteBytes,
                    networkConnectionsCount: count,
                    energyImpact: current.energyImpact,
                    gpuUsage: current.gpuUsage
                )
            }
        }
    }
    
    // MARK: - Real-time Monitoring
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitoringTask = Task {
            while !Task.isCancelled && isMonitoring {
                await refreshProcesses()
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    // MARK: - Filtering and Sorting
    
    func applyFiltersAndSort() {
        var filtered = processes
        
        // Apply search filter
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { process in
                process.name.lowercased().contains(searchLower) ||
                process.bundleIdentifier?.lowercased().contains(searchLower) ?? false ||
                "\(process.id)".contains(searchText) ||
                process.executablePath?.lowercased().contains(searchLower) ?? false
            }
        }
        
        // Apply type filter
        switch currentFilter {
        case .all:
            break
        case .user:
            filtered = filtered.filter { $0.isUserProcess }
        case .system:
            filtered = filtered.filter { !$0.isUserProcess }
        case .applications:
            filtered = filtered.filter { $0.bundleIdentifier != nil }
        }
        
        // Apply sorting
        filtered.sort(by: { process1, process2 in
            let comparison: Bool
            switch currentSort {
            case .cpu:
                comparison = process1.cpuUsage < process2.cpuUsage
            case .memory:
                comparison = process1.memoryUsage < process2.memoryUsage
            case .name:
                comparison = process1.name < process2.name
            case .pid:
                comparison = process1.id < process2.id
            case .threads:
                comparison = process1.threadCount < process2.threadCount
            }
            return sortAscending ? comparison : !comparison
        })
        
        filteredProcesses = filtered
    }
    
    // MARK: - Process Actions
    
    func killProcess(_ processInfo: ProcessInfo) throws {
        let killProcess = Process()
        killProcess.executableURL = URL(fileURLWithPath: "/bin/kill")
        killProcess.arguments = ["-9", "\(processInfo.id)"]
        
        try killProcess.run()
        killProcess.waitUntilExit()
        
        // Remove from list
        processes.removeAll { $0.id == processInfo.id }
        applyFiltersAndSort()
    }
    
    func forceQuitProcess(_ processInfo: ProcessInfo) {
        if let app = NSRunningApplication(processIdentifier: pid_t(processInfo.id)) {
            app.forceTerminate()
        } else {
            try? killProcess(processInfo)
        }
    }
    
    func showInFinder(_ processInfo: ProcessInfo) {
        guard let executablePath = processInfo.executablePath else { return }
        let url = URL(fileURLWithPath: executablePath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    // MARK: - Statistics
    
    var totalProcessCount: Int {
        processes.count
    }
    
    var userProcessCount: Int {
        processes.filter { $0.isUserProcess }.count
    }
    
    var systemProcessCount: Int {
        processes.filter { !$0.isUserProcess }.count
    }
    
    var totalMemoryUsage: Int64 {
        processes.reduce(into: Int64(0)) { $0 += $1.memoryUsage }
    }
    
    var totalCPUUsage: Double {
        processes.reduce(into: Double(0)) { $0 += $1.cpuUsage }
    }
}


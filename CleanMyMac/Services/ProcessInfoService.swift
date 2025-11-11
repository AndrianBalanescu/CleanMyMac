//
//  ProcessInfoService.swift
//  CleanMyMac
//
//  Service to gather detailed process information using macOS APIs
//

import Foundation
import AppKit
import Darwin
import IOKit

class ProcessInfoService {
    static let shared = ProcessInfoService()
    
    private init() {}
    
    // MARK: - Main Process Info Gathering
    
    func getDetailedProcessInfo(pid: Int32) async -> ProcessInfo? {
        var processInfo = ProcessInfo(
            id: pid,
            name: "Unknown",
            state: .unknown,
            isUserProcess: pid > 100
        )
        
        // Get basic info from sysctl (fast, no special permissions needed)
        if let basicInfo = getProcessBasicInfo(pid: pid) {
            processInfo = processInfo.merging(basicInfo)
        }
        
        // Get NSRunningApplication info if available (fast, no special permissions needed)
        if let appInfo = getNSRunningApplicationInfo(pid: pid) {
            processInfo = processInfo.merging(appInfo)
        }
        
        // Get memory info from ps command (fast, no special permissions needed)
        if let memoryInfo = getMemoryInfoFromPS(pid: pid) {
            processInfo = processInfo.merging(memoryInfo)
        }
        
        // Skip Mach task APIs for now - they require special entitlements and are slow
        // This causes the hanging issue. Uncomment below if you have proper entitlements:
        /*
        if processInfo.isUserProcess {
            if let taskInfo = await getTaskInfo(pid: pid) {
                processInfo = processInfo.merging(taskInfo)
            }
        }
        */
        
        // Get command line and environment (can be slow, but usually works)
        // Skip if it takes too long - use timeout
        if let cmdInfo = await withTimeout(seconds: 0.1, operation: {
            self.getCommandLineInfo(pid: pid)
        }) {
            processInfo = processInfo.merging(cmdInfo)
        }
        
        return processInfo
    }
    
    // Helper to add timeout to synchronous operations
    private func withTimeout<T>(seconds: Double, operation: @escaping () -> T?) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            group.addTask {
                // Run on background thread to avoid blocking
                await Task.detached {
                    operation()
                }.value
            }
            
            for await result in group {
                if let value = result {
                    return value
                }
            }
            return nil
        }
    }
    
    func getAllProcessPIDs() -> [Int32] {
        var mib = [CTL_KERN, KERN_PROC, KERN_PROC_ALL]
        var size = 0
        
        // Get size needed
        if sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) != 0 {
            return []
        }
        
        // Allocate buffer
        let count = size / MemoryLayout<kinfo_proc>.size
        let buffer = UnsafeMutablePointer<kinfo_proc>.allocate(capacity: count)
        defer { buffer.deallocate() }
        
        // Get process list
        if sysctl(&mib, u_int(mib.count), buffer, &size, nil, 0) != 0 {
            return []
        }
        
        var pids: [Int32] = []
        for i in 0..<count {
            pids.append(buffer[i].kp_proc.p_pid)
        }
        
        return pids
    }
    
    // MARK: - sysctl-based Info
    
    private func getProcessBasicInfo(pid: Int32) -> ProcessInfo? {
        var mib = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        var proc = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size
        
        guard sysctl(&mib, u_int(mib.count), &proc, &size, nil, 0) == 0 else {
            return nil
        }
        
        let name = withUnsafePointer(to: &proc.kp_proc.p_comm) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXCOMLEN)) {
                String(cString: $0)
            }
        }
        
        let state = getProcessState(from: UInt8(bitPattern: proc.kp_proc.p_stat))
        
        return ProcessInfo(
            id: pid,
            name: name,
            state: state,
            priority: Int32(proc.kp_proc.p_priority),
            niceValue: Int32(proc.kp_proc.p_nice),
            realUID: proc.kp_eproc.e_pcred.p_ruid,
            effectiveUID: proc.kp_eproc.e_ucred.cr_uid,
            realGID: proc.kp_eproc.e_pcred.p_rgid,
            effectiveGID: proc.kp_eproc.e_ucred.cr_groups.0,
            processGroupID: proc.kp_eproc.e_pgid,
            sessionID: nil, // e_sessid not available in this struct
            parentPID: proc.kp_eproc.e_ppid,
            startTime: Date(timeIntervalSince1970: TimeInterval(proc.kp_proc.p_starttime.tv_sec)),
            isUserProcess: proc.kp_eproc.e_ucred.cr_uid != 0
        )
    }
    
    private func getProcessState(from stat: UInt8) -> ProcessState {
        switch stat {
        case 1: return .idle
        case 2: return .running
        case 3: return .sleeping
        case 4: return .stopped
        case 5: return .zombie
        default: return .unknown
        }
    }
    
    private func getCommandLineInfo(pid: Int32) -> ProcessInfo? {
        // Get command line using KERN_PROCARGS2
        var mib = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        
        // Get size
        if sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) != 0 {
            return nil
        }
        
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: size)
        defer { buffer.deallocate() }
        
        if sysctl(&mib, u_int(mib.count), buffer, &size, nil, 0) != 0 {
            return nil
        }
        
        // Parse command line arguments
        var offset = 0
        let argc = buffer.advanced(by: offset).withMemoryRebound(to: Int32.self, capacity: 1) { $0.pointee }
        offset += MemoryLayout<Int32>.size
        
        var args: [String] = []
        var currentArg = ""
        
        for _ in 0..<Int(argc) {
            currentArg = ""
            while offset < size && buffer[offset] != 0 {
                currentArg.append(Character(UnicodeScalar(UInt8(buffer[offset]))))
                offset += 1
            }
            if !currentArg.isEmpty {
                args.append(currentArg)
            }
            offset += 1 // Skip null terminator
        }
        
        // Get executable path (first argument)
        let executablePath = args.first
        
        // Get working directory (simplified - would need proc_pidinfo for accurate path)
        let workingDirectory = executablePath?.deletingLastPathComponent()
        
        return ProcessInfo(
            id: pid,
            name: "",
            executablePath: executablePath,
            workingDirectory: workingDirectory,
            commandLine: args.isEmpty ? nil : args
        )
    }
    
    // MARK: - Mach Task Info
    
    private func getTaskInfo(pid: Int32) async -> ProcessInfo? {
        var task: task_t = 0
        let result = task_for_pid(mach_task_self_, pid, &task)
        guard result == KERN_SUCCESS else {
            return nil
        }
        
        var taskInfo = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size / MemoryLayout<integer_t>.size)
        
        let result2 = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(task, task_flavor_t(TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result2 == KERN_SUCCESS else {
            return nil
        }
        
        // Get VM info
        var vmInfo = task_vm_info()
        var vmCount = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size / MemoryLayout<integer_t>.size)
        
        let vmResult = withUnsafeMutablePointer(to: &vmInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(vmCount)) {
                task_info(task, task_flavor_t(TASK_VM_INFO), $0, &vmCount)
            }
        }
        
        // Get thread times
        var threadTimes = task_thread_times_info()
        var threadCount = mach_msg_type_number_t(MemoryLayout<task_thread_times_info>.size / MemoryLayout<integer_t>.size)
        
        let threadResult = withUnsafeMutablePointer(to: &threadTimes) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(threadCount)) {
                task_info(task, task_flavor_t(TASK_THREAD_TIMES_INFO), $0, &threadCount)
            }
        }
        
        // Get events info
        var eventsInfo = task_events_info()
        var eventsCount = mach_msg_type_number_t(MemoryLayout<task_events_info>.size / MemoryLayout<integer_t>.size)
        
        let eventsResult = withUnsafeMutablePointer(to: &eventsInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(eventsCount)) {
                task_info(task, task_flavor_t(TASK_EVENTS_INFO), $0, &eventsCount)
            }
        }
        
        let cpuTimeUser = threadResult == KERN_SUCCESS ? Double(threadTimes.user_time.seconds) + Double(threadTimes.user_time.microseconds) / 1_000_000.0 : 0
        let cpuTimeSystem = threadResult == KERN_SUCCESS ? Double(threadTimes.system_time.seconds) + Double(threadTimes.system_time.microseconds) / 1_000_000.0 : 0
        
        let virtualMemory = Int64(vmResult == KERN_SUCCESS ? vmInfo.virtual_size : 0)
        let residentMemory = Int64(taskInfo.resident_size)
        let sharedMemory = Int64(vmResult == KERN_SUCCESS ? vmInfo.internal : 0)
        
        let pageFaults = eventsResult == KERN_SUCCESS ? Int64(eventsInfo.faults) : nil
        let pageIns = eventsResult == KERN_SUCCESS ? Int64(eventsInfo.pageins) : nil
        // pageOuts not available in task_events_info
        
        return ProcessInfo(
            id: pid,
            name: "",
            cpuTimeUser: cpuTimeUser,
            cpuTimeSystem: cpuTimeSystem,
            memoryUsage: residentMemory,
            virtualMemorySize: virtualMemory,
            sharedMemorySize: sharedMemory,
            threadCount: 0, // thread_count not directly available, would need thread_list
            pageFaults: pageFaults,
            pageIns: pageIns,
            pageOuts: nil
        )
    }
    
    // MARK: - NSRunningApplication Info
    
    private func getNSRunningApplicationInfo(pid: Int32) -> ProcessInfo? {
        guard let app = NSRunningApplication(processIdentifier: pid_t(pid)) else {
            return nil
        }
        
        let activationPolicy: ActivationPolicy
        switch app.activationPolicy {
        case .regular:
            activationPolicy = .regular
        case .accessory:
            activationPolicy = .accessory
        case .prohibited:
            activationPolicy = .prohibited
        @unknown default:
            activationPolicy = .unknown
        }
        
        var iconData: Data? = nil
        if let icon = app.icon {
            iconData = icon.tiffRepresentation
        }
        
        return ProcessInfo(
            id: pid,
            name: app.localizedName ?? "Unknown",
            bundleIdentifier: app.bundleIdentifier,
            executablePath: app.executableURL?.path,
            launchDate: app.launchDate,
            activationPolicy: activationPolicy,
            processSerialNumber: nil, // Not available in NSRunningApplication
            isFinishedLaunching: app.isFinishedLaunching,
            isHidden: app.isHidden,
            ownsMenuBar: app.ownsMenuBar,
            icon: iconData
        )
    }
    
    // MARK: - Memory Info from PS (Fast, no special permissions)
    
    private func getMemoryInfoFromPS(pid: Int32) -> ProcessInfo? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", "\(pid)", "-o", "rss=,vsz=,thcount="]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // Suppress errors
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let components = output.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            guard components.count >= 2 else { return nil }
            
            // RSS is in KB, VSZ is in KB
            let rssKB = Int64(components[0]) ?? 0
            let vszKB = Int64(components[1]) ?? 0
            let threadCount = components.count >= 3 ? (Int(components[2]) ?? 0) : 0
            
            return ProcessInfo(
                id: pid,
                name: "",
                memoryUsage: rssKB * 1024, // Convert KB to bytes
                virtualMemorySize: vszKB * 1024, // Convert KB to bytes
                threadCount: threadCount
            )
        } catch {
            return nil
        }
    }
    
    // MARK: - I/O Statistics
    
    private func getIOStats(pid: Int32) async -> ProcessInfo? {
        // Use iostat or sample for I/O stats
        // For now, use a simplified approach with ps command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", "\(pid)", "-o", "rss=,vsz="]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let components = output.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            // Note: This is a simplified approach. Real I/O stats would require more complex APIs
            return nil // Placeholder for now
        } catch {
            return nil
        }
    }
    
    // MARK: - CPU Usage Calculation
    
    func calculateCPUUsage(pid: Int32, previousTime: inout timeval, previousTicks: inout UInt64) -> Double {
        var task: task_t = 0
        guard task_for_pid(mach_task_self_, pid, &task) == KERN_SUCCESS else {
            return 0
        }
        
        var threadTimes = task_thread_times_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_thread_times_info>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &threadTimes) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(task, task_flavor_t(TASK_THREAD_TIMES_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return 0
        }
        
        let currentTicks = UInt64(threadTimes.user_time.seconds) * 1000000 + UInt64(threadTimes.user_time.microseconds) +
                          UInt64(threadTimes.system_time.seconds) * 1000000 + UInt64(threadTimes.system_time.microseconds)
        
        var currentTime = timeval()
        gettimeofday(&currentTime, nil)
        
        let timeDiff = Double(currentTime.tv_sec - previousTime.tv_sec) + Double(currentTime.tv_usec - previousTime.tv_usec) / 1_000_000.0
        let ticksDiff = Double(currentTicks - previousTicks) / 1_000_000.0
        
        previousTime = currentTime
        previousTicks = currentTicks
        
        guard timeDiff > 0 else { return 0 }
        
        return min(100.0, (ticksDiff / timeDiff) * 100.0)
    }
}

// MARK: - ProcessInfo Extension for Merging

extension ProcessInfo {
    func merging(_ other: ProcessInfo) -> ProcessInfo {
        ProcessInfo(
            id: self.id,
            name: other.name.isEmpty ? self.name : other.name,
            bundleIdentifier: other.bundleIdentifier ?? self.bundleIdentifier,
            executablePath: other.executablePath ?? self.executablePath,
            workingDirectory: other.workingDirectory ?? self.workingDirectory,
            commandLine: other.commandLine ?? self.commandLine,
            environment: other.environment ?? self.environment,
            cpuUsage: other.cpuUsage != 0 ? other.cpuUsage : self.cpuUsage,
            cpuTimeUser: other.cpuTimeUser != 0 ? other.cpuTimeUser : self.cpuTimeUser,
            cpuTimeSystem: other.cpuTimeSystem != 0 ? other.cpuTimeSystem : self.cpuTimeSystem,
            memoryUsage: other.memoryUsage != 0 ? other.memoryUsage : self.memoryUsage,
            virtualMemorySize: other.virtualMemorySize != 0 ? other.virtualMemorySize : self.virtualMemorySize,
            sharedMemorySize: other.sharedMemorySize != 0 ? other.sharedMemorySize : self.sharedMemorySize,
            threadCount: other.threadCount != 0 ? other.threadCount : self.threadCount,
            fileDescriptorCount: other.fileDescriptorCount ?? self.fileDescriptorCount,
            state: other.state != .unknown ? other.state : self.state,
            priority: other.priority ?? self.priority,
            niceValue: other.niceValue ?? self.niceValue,
            realUID: other.realUID ?? self.realUID,
            effectiveUID: other.effectiveUID ?? self.effectiveUID,
            realGID: other.realGID ?? self.realGID,
            effectiveGID: other.effectiveGID ?? self.effectiveGID,
            processGroupID: other.processGroupID ?? self.processGroupID,
            sessionID: other.sessionID ?? self.sessionID,
            parentPID: other.parentPID ?? self.parentPID,
            startTime: other.startTime ?? self.startTime,
            launchDate: other.launchDate ?? self.launchDate,
            isUserProcess: other.isUserProcess,
            pageFaults: other.pageFaults ?? self.pageFaults,
            pageIns: other.pageIns ?? self.pageIns,
            pageOuts: other.pageOuts ?? self.pageOuts,
            activationPolicy: other.activationPolicy ?? self.activationPolicy,
            processSerialNumber: other.processSerialNumber ?? self.processSerialNumber,
            isFinishedLaunching: other.isFinishedLaunching ?? self.isFinishedLaunching,
            isHidden: other.isHidden ?? self.isHidden,
            ownsMenuBar: other.ownsMenuBar ?? self.ownsMenuBar,
            icon: other.icon ?? self.icon,
            bytesRead: other.bytesRead ?? self.bytesRead,
            bytesWritten: other.bytesWritten ?? self.bytesWritten,
            diskReadBytes: other.diskReadBytes ?? self.diskReadBytes,
            diskWriteBytes: other.diskWriteBytes ?? self.diskWriteBytes,
            networkConnectionsCount: other.networkConnectionsCount ?? self.networkConnectionsCount,
            energyImpact: other.energyImpact ?? self.energyImpact,
            gpuUsage: other.gpuUsage ?? self.gpuUsage
        )
    }
}

// MARK: - String Extension

extension String {
    func deletingLastPathComponent() -> String {
        (self as NSString).deletingLastPathComponent
    }
}


//
//  ProcessDetailView.swift
//  CleanMyMac
//
//  Detailed process information view with tabs
//

import SwiftUI
import AppKit

struct ProcessDetailView: View {
    let process: ProcessInfo
    @State private var selectedTab: DetailTab = .overview
    
    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case memory = "Memory"
        case cpu = "CPU"
        case threads = "Threads"
        case io = "I/O"
        case network = "Network"
        case permissions = "Permissions"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Icon
                    if let iconData = process.icon,
                       let nsImage = NSImage(data: iconData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .frame(width: 48, height: 48)
                    } else {
                        Image(systemName: "app.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(process.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let bundleId = process.bundleIdentifier {
                            Text(bundleId)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("PID: \(process.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .glassBackground()
            
            // Tabs
            Picker("Tab", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            ScrollView {
                Group {
                    switch selectedTab {
                    case .overview:
                        overviewTab
                    case .memory:
                        memoryTab
                    case .cpu:
                        cpuTab
                    case .threads:
                        threadsTab
                    case .io:
                        ioTab
                    case .network:
                        networkTab
                    case .permissions:
                        permissionsTab
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Basic Information
            SectionView(title: "Basic Information") {
                InfoGrid {
                    InfoRow(label: "Process ID", value: "\(process.id)")
                    if let parentPID = process.parentPID {
                        InfoRow(label: "Parent PID", value: "\(parentPID)")
                    }
                    InfoRow(label: "State", value: process.state.rawValue)
                    if let priority = process.priority {
                        InfoRow(label: "Priority", value: "\(priority)")
                    }
                    if let nice = process.niceValue {
                        InfoRow(label: "Nice Value", value: "\(nice)")
                    }
                    if let uptime = process.uptime {
                        InfoRow(label: "Uptime", value: process.displayUptime)
                    }
                    if let startTime = process.startTime {
                        InfoRow(label: "Start Time", value: startTime.formatted())
                    }
                    if let launchDate = process.launchDate {
                        InfoRow(label: "Launch Date", value: launchDate.formatted())
                    }
                }
            }
            
            // Process Hierarchy
            if let parentPID = process.parentPID {
                SectionView(title: "Process Hierarchy") {
                    InfoGrid {
                        InfoRow(label: "Parent PID", value: "\(parentPID)")
                        if let pgid = process.processGroupID {
                            InfoRow(label: "Process Group ID", value: "\(pgid)")
                        }
                        if let sid = process.sessionID {
                            InfoRow(label: "Session ID", value: "\(sid)")
                        }
                    }
                }
            }
            
            // Executable Information
            SectionView(title: "Executable Information") {
                VStack(alignment: .leading, spacing: 8) {
                    if let executablePath = process.executablePath {
                        InfoRow(label: "Executable Path", value: executablePath)
                            .font(.system(.body, design: .monospaced))
                    }
                    if let workingDir = process.workingDirectory {
                        InfoRow(label: "Working Directory", value: workingDir)
                            .font(.system(.body, design: .monospaced))
                    }
                    if let commandLine = process.commandLine, !commandLine.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Command Line:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(commandLine.joined(separator: " "))
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            
            // AppKit Information
            if process.activationPolicy != nil || process.isHidden != nil || process.ownsMenuBar != nil {
                SectionView(title: "AppKit Information") {
                    InfoGrid {
                        if let policy = process.activationPolicy {
                            InfoRow(label: "Activation Policy", value: policy.rawValue)
                        }
                        if let isHidden = process.isHidden {
                            InfoRow(label: "Hidden", value: isHidden ? "Yes" : "No")
                        }
                        if let ownsMenuBar = process.ownsMenuBar {
                            InfoRow(label: "Owns Menu Bar", value: ownsMenuBar ? "Yes" : "No")
                        }
                        if let isFinishedLaunching = process.isFinishedLaunching {
                            InfoRow(label: "Finished Launching", value: isFinishedLaunching ? "Yes" : "No")
                        }
                        if let serialNumber = process.processSerialNumber {
                            InfoRow(label: "Process Serial Number", value: String(format: "0x%llX", serialNumber))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Memory Tab
    
    private var memoryTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionView(title: "Memory Usage") {
                VStack(alignment: .leading, spacing: 12) {
                    MemoryBar(label: "Resident Memory (RSS)", value: process.memoryUsage, color: .blue)
                    MemoryBar(label: "Virtual Memory", value: process.virtualMemorySize, color: .green)
                    MemoryBar(label: "Shared Memory", value: process.sharedMemorySize, color: .orange)
                }
            }
            
            SectionView(title: "Memory Statistics") {
                InfoGrid {
                    InfoRow(label: "Resident Memory", value: process.displayMemoryUsage)
                    InfoRow(label: "Virtual Memory", value: process.displayVirtualMemory)
                    InfoRow(label: "Shared Memory", value: process.displaySharedMemory)
                    if let pageFaults = process.pageFaults {
                        InfoRow(label: "Page Faults", value: "\(pageFaults)")
                    }
                    if let pageIns = process.pageIns {
                        InfoRow(label: "Page Ins", value: "\(pageIns)")
                    }
                    if let pageOuts = process.pageOuts {
                        InfoRow(label: "Page Outs", value: "\(pageOuts)")
                    }
                }
            }
        }
    }
    
    // MARK: - CPU Tab
    
    private var cpuTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionView(title: "CPU Usage") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Current CPU Usage")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.2f%%", process.cpuUsage))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(cpuColor)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 20)
                                .cornerRadius(10)
                            
                            Rectangle()
                                .fill(cpuColor)
                                .frame(width: geometry.size.width * CGFloat(min(process.cpuUsage / 100.0, 1.0)), height: 20)
                                .cornerRadius(10)
                        }
                    }
                    .frame(height: 20)
                }
            }
            
            SectionView(title: "CPU Time") {
                InfoGrid {
                    InfoRow(label: "Total CPU Time", value: process.displayCPUTime)
                    InfoRow(label: "User CPU Time", value: String(format: "%.2fs", process.cpuTimeUser))
                    InfoRow(label: "System CPU Time", value: String(format: "%.2fs", process.cpuTimeSystem))
                }
            }
        }
    }
    
    // MARK: - Threads Tab
    
    private var threadsTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionView(title: "Thread Information") {
                InfoGrid {
                    InfoRow(label: "Thread Count", value: "\(process.threadCount)")
                    if let fdCount = process.fileDescriptorCount {
                        InfoRow(label: "File Descriptors", value: "\(fdCount)")
                    }
                }
            }
            
            // Note: Detailed thread information would require additional APIs
            Text("Detailed thread information requires additional system APIs")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    // MARK: - I/O Tab
    
    private var ioTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionView(title: "I/O Statistics") {
                InfoGrid {
                    if let bytesRead = process.bytesRead {
                        InfoRow(label: "Bytes Read", value: ByteCountFormatter.string(fromByteCount: bytesRead, countStyle: .file))
                    } else {
                        InfoRow(label: "Bytes Read", value: "N/A")
                    }
                    if let bytesWritten = process.bytesWritten {
                        InfoRow(label: "Bytes Written", value: ByteCountFormatter.string(fromByteCount: bytesWritten, countStyle: .file))
                    } else {
                        InfoRow(label: "Bytes Written", value: "N/A")
                    }
                    if let diskRead = process.diskReadBytes {
                        InfoRow(label: "Disk Read", value: ByteCountFormatter.string(fromByteCount: diskRead, countStyle: .file))
                    } else {
                        InfoRow(label: "Disk Read", value: "N/A")
                    }
                    if let diskWrite = process.diskWriteBytes {
                        InfoRow(label: "Disk Write", value: ByteCountFormatter.string(fromByteCount: diskWrite, countStyle: .file))
                    } else {
                        InfoRow(label: "Disk Write", value: "N/A")
                    }
                }
            }
            
            Text("Note: I/O statistics may require Full Disk Access permission")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    // MARK: - Network Tab
    
    private var networkTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionView(title: "Network Information") {
                InfoGrid {
                    if let networkCount = process.networkConnectionsCount {
                        InfoRow(label: "Network Connections", value: "\(networkCount)")
                    } else {
                        InfoRow(label: "Network Connections", value: "0")
                    }
                }
            }
            
            Text("Note: Detailed network connection information requires additional APIs")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    // MARK: - Permissions Tab
    
    private var permissionsTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionView(title: "User and Group IDs") {
                InfoGrid {
                    if let realUID = process.realUID {
                        InfoRow(label: "Real UID", value: "\(realUID)")
                    }
                    if let effectiveUID = process.effectiveUID {
                        InfoRow(label: "Effective UID", value: "\(effectiveUID)")
                    }
                    if let realGID = process.realGID {
                        InfoRow(label: "Real GID", value: "\(realGID)")
                    }
                    if let effectiveGID = process.effectiveGID {
                        InfoRow(label: "Effective GID", value: "\(effectiveGID)")
                    }
                    InfoRow(label: "User Process", value: process.isUserProcess ? "Yes" : "No")
                }
            }
            
            if let environment = process.environment, !environment.isEmpty {
                SectionView(title: "Environment Variables") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(environment.keys.sorted()), id: \.self) { key in
                                HStack(alignment: .top) {
                                    Text(key + "=")
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Text(environment[key] ?? "")
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
        }
    }
    
    private var cpuColor: Color {
        if process.cpuUsage > 80 {
            return .red
        } else if process.cpuUsage > 50 {
            return .orange
        } else if process.cpuUsage > 20 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Supporting Views

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .glassBackground()
    }
}

struct InfoGrid<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
    }
}

struct MemoryBar: View {
    let label: String
    let value: Int64
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: value, countStyle: .memory))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: min(geometry.size.width, geometry.size.width * 0.8), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}





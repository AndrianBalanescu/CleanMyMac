//
//  ProcessRowView.swift
//  CleanMyMac
//
//  Enhanced process row with expandable details
//

import SwiftUI
import AppKit

struct ProcessRowView: View {
    let process: ProcessInfo
    let onKill: () -> Void
    let onForceQuit: () -> Void
    let onShowInFinder: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                // Icon
                if let iconData = process.icon,
                   let nsImage = NSImage(data: iconData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "app.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                }
                
                // Basic Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(process.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Text("PID: \(process.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let bundleId = process.bundleIdentifier {
                            Text(bundleId)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Text(process.state.rawValue)
                            .font(.caption)
                            .foregroundColor(stateColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(stateColor.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Resource Usage
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 16) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f%%", process.cpuUsage))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("CPU")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(process.displayMemoryUsage)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Memory")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(process.threadCount)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Threads")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Actions
                HStack(spacing: 8) {
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Menu {
                        Button("Show in Finder", action: onShowInFinder)
                        Divider()
                        Button("Force Quit", action: onForceQuit)
                        Button(role: .destructive, action: onKill) {
                            Label("Kill Process", systemImage: "xmark.circle.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
            
            // Expanded Details
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    // Process Details Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], alignment: .leading, spacing: 16) {
                        // Basic Info
                        DetailSection(title: "Process Info") {
                            InfoRow(label: "PID", value: "\(process.id)")
                            if let parentPID = process.parentPID {
                                InfoRow(label: "Parent PID", value: "\(parentPID)")
                            }
                            if let pgid = process.processGroupID {
                                InfoRow(label: "Process Group", value: "\(pgid)")
                            }
                            if let sid = process.sessionID {
                                InfoRow(label: "Session ID", value: "\(sid)")
                            }
                            if let uptime = process.uptime {
                                InfoRow(label: "Uptime", value: process.displayUptime)
                            }
                        }
                        
                        // Resource Usage
                        DetailSection(title: "Resources") {
                            InfoRow(label: "CPU Time", value: process.displayCPUTime)
                            InfoRow(label: "Virtual Memory", value: process.displayVirtualMemory)
                            InfoRow(label: "Shared Memory", value: process.displaySharedMemory)
                            if let fdCount = process.fileDescriptorCount {
                                InfoRow(label: "File Descriptors", value: "\(fdCount)")
                            }
                            if let networkCount = process.networkConnectionsCount {
                                InfoRow(label: "Network Connections", value: "\(networkCount)")
                            }
                        }
                        
                        // System Info
                        DetailSection(title: "System") {
                            if let priority = process.priority {
                                InfoRow(label: "Priority", value: "\(priority)")
                            }
                            if let nice = process.niceValue {
                                InfoRow(label: "Nice", value: "\(nice)")
                            }
                            if let realUID = process.realUID {
                                InfoRow(label: "Real UID", value: "\(realUID)")
                            }
                            if let effectiveUID = process.effectiveUID {
                                InfoRow(label: "Effective UID", value: "\(effectiveUID)")
                            }
                            if let pageFaults = process.pageFaults {
                                InfoRow(label: "Page Faults", value: "\(pageFaults)")
                            }
                        }
                    }
                    
                    // Executable Path
                    if let executablePath = process.executablePath {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Executable Path")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(executablePath)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                    
                    // Working Directory
                    if let workingDir = process.workingDirectory {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Working Directory")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(workingDir)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                    
                    // Command Line
                    if let commandLine = process.commandLine, !commandLine.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Command Line")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(commandLine.joined(separator: " "))
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .lineLimit(3)
                        }
                    }
                    
                    // AppKit Info
                    if process.activationPolicy != nil || process.isHidden != nil || process.ownsMenuBar != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AppKit Info")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 16) {
                                if let policy = process.activationPolicy {
                                    InfoRow(label: "Activation Policy", value: policy.rawValue)
                                }
                                if let isHidden = process.isHidden {
                                    InfoRow(label: "Hidden", value: isHidden ? "Yes" : "No")
                                }
                                if let ownsMenuBar = process.ownsMenuBar {
                                    InfoRow(label: "Owns Menu Bar", value: ownsMenuBar ? "Yes" : "No")
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.05))
            }
        }
        .glassBackground()
    }
    
    private var stateColor: Color {
        switch process.state {
        case .running:
            return .green
        case .sleeping:
            return .blue
        case .zombie:
            return .red
        case .stopped:
            return .orange
        case .idle:
            return .gray
        case .unknown:
            return .secondary
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                content
            }
        }
    }
}





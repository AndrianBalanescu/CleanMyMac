//
//  SystemMonitorView.swift
//  CleanMyMac
//
//  Real-time system monitoring
//

import SwiftUI

struct SystemMonitorView: View {
    @StateObject private var monitor = SystemMonitor()
    @StateObject private var processManager = ProcessManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("System Monitor")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(monitor.isMonitoring ? "Stop" : "Start") {
                    if monitor.isMonitoring {
                        monitor.stopMonitoring()
                    } else {
                        monitor.startMonitoring()
                    }
                }
                .buttonStyle(GlassButton())
            }
            .padding()
            .glassBackground()
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Current Metrics
                    if let metric = monitor.currentMetric {
                        VStack(spacing: 16) {
                            // CPU Usage
                            MetricCard(
                                title: "CPU Usage",
                                value: String(format: "%.1f%%", metric.cpuUsage),
                                color: .blue
                            )
                            
                            // Memory Usage
                            MetricCard(
                                title: "Memory",
                                value: "\(metric.displayMemoryUsed) / \(metric.displayMemoryTotal)",
                                subtitle: String(format: "%.1f%%", metric.memoryUsagePercent),
                                color: .green
                            )
                            
                            // Memory Progress Bar
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Memory Usage")
                                    .font(.headline)
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 20)
                                            .cornerRadius(10)
                                        
                                        Rectangle()
                                            .fill(Color.green)
                                            .frame(width: geometry.size.width * CGFloat(metric.memoryUsagePercent / 100), height: 20)
                                            .cornerRadius(10)
                                    }
                                }
                                .frame(height: 20)
                            }
                            .padding()
                            .glassBackground()
                        }
                        .padding()
                    }
                    
                    // Processes
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Running Processes")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button("Refresh") {
                                Task {
                                    await processManager.refreshProcesses()
                                }
                            }
                            .buttonStyle(GlassButton())
                        }
                        
                        if processManager.isLoading {
                            ProgressView()
                        } else {
                            ForEach(processManager.processes.prefix(20)) { process in
                                ProcessRow(process: process) {
                                    try? processManager.killProcess(process)
                                }
                            }
                        }
                    }
                    .padding()
                    .glassBackground()
                }
                .padding()
            }
        }
        .task {
            await processManager.refreshProcesses()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassBackground()
    }
}

struct ProcessRow: View {
    let process: ProcessInfo
    let onKill: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(process.name)
                    .font(.headline)
                Text("PID: \(process.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "CPU: %.1f%%", process.cpuUsage))
                    .font(.subheadline)
                Text(process.displayMemoryUsage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button {
                onKill()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassBackground()
    }
}


//
//  DashboardView.swift
//  CleanMyMac
//
//  Main dashboard with system overview
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var systemMonitor = SystemMonitor()
    @StateObject private var storageAnalyzer = StorageAnalyzer()
    @StateObject private var batteryMonitor = BatteryMonitor()
    @StateObject private var settings = ScanSettings.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Welcome/Info Card
                if !settings.scanSystemMetrics && !settings.scanStorage {
                    WelcomeCard()
                        .padding()
                }
                
                // System Metrics
                if let metric = systemMonitor.currentMetric {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("System Performance")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 16) {
                            MetricCard(
                                title: "CPU",
                                value: String(format: "%.1f%%", metric.cpuUsage),
                                color: .blue
                            )
                            
                            MetricCard(
                                title: "Memory",
                                value: String(format: "%.1f%%", metric.memoryUsagePercent),
                                subtitle: metric.displayMemoryUsed,
                                color: .green
                            )
                            
                            if let capacity = batteryMonitor.currentCapacity {
                                MetricCard(
                                    title: "Battery",
                                    value: "\(capacity)%",
                                    subtitle: batteryMonitor.isCharging ? "Charging" : "Discharging",
                                    color: .orange
                                )
                            }
                        }
                    }
                    .padding()
                    .glassBackground()
                }
                
                // Storage Overview
                if let breakdown = storageAnalyzer.breakdown {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Storage Overview")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Total: \(breakdown.displayTotalSize)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        // Top categories
                        ForEach(Array(breakdown.byCategory.keys.sorted {
                            (breakdown.byCategory[$0] ?? 0) > (breakdown.byCategory[$1] ?? 0)
                        }.prefix(5)), id: \.self) { category in
                            if let size = breakdown.byCategory[category] {
                                StorageCategoryRow(
                                    category: category,
                                    size: size,
                                    totalSize: breakdown.totalSize
                                )
                            }
                        }
                    }
                    .padding()
                    .glassBackground()
                }
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        Button("Analyze Storage") {
                            Task {
                                await storageAnalyzer.analyzeStorage()
                            }
                        }
                        .buttonStyle(GlassButton())
                        
                        if !systemMonitor.isMonitoring {
                            Button("Start System Monitoring") {
                                settings.scanSystemMetrics = true
                                systemMonitor.startMonitoring()
                            }
                            .buttonStyle(GlassButton())
                        } else {
                            Button("Stop Monitoring") {
                                systemMonitor.stopMonitoring()
                                settings.scanSystemMetrics = false
                            }
                            .buttonStyle(GlassButton())
                        }
                        
                        if batteryMonitor.currentCapacity != nil {
                            Button("Refresh Battery") {
                                Task {
                                    await batteryMonitor.refreshBatteryInfo()
                                }
                            }
                            .buttonStyle(GlassButton())
                        }
                    }
                }
                .padding()
                .glassBackground()
            }
            .padding()
        }
        .onAppear {
            // Only auto-start if user has enabled it in settings
            if settings.autoStartMonitoring && settings.scanSystemMetrics {
                systemMonitor.startMonitoring()
            }
            // Don't auto-scan anything else
        }
    }
}

struct WelcomeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundColor(.blue)
                Text("Welcome to MyMac")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Text("Get started by choosing what you'd like to scan or monitor:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "app.badge")
                        .foregroundColor(.blue)
                    Text("Apps - View and manage installed applications")
                }
                .font(.caption)
                
                HStack {
                    Image(systemName: "externaldrive.fill")
                        .foregroundColor(.green)
                    Text("Storage - Analyze disk usage and find large files")
                }
                .font(.caption)
                
                HStack {
                    Image(systemName: "cpu")
                        .foregroundColor(.orange)
                    Text("System - Monitor CPU, memory, and processes")
                }
                .font(.caption)
            }
            .padding(.vertical, 8)
        }
        .padding()
        .glassBackground()
    }
}


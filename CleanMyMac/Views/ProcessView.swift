//
//  ProcessView.swift
//  CleanMyMac
//
//  Comprehensive process monitoring view
//

import SwiftUI

struct ProcessView: View {
    @StateObject private var processManager = ProcessManager()
    @State private var selectedProcess: ProcessInfo?
    @State private var showDetailPanel = false
    
    var body: some View {
        HSplitView {
            // Main Content
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Toolbar
                toolbarView
                
                // Process List
                processListView
            }
            
            // Detail Panel
            if showDetailPanel, let process = selectedProcess {
                ProcessDetailView(process: process)
                    .frame(minWidth: 400)
            }
        }
        .task {
            await processManager.refreshProcesses()
        }
        .onChange(of: processManager.searchText) { _ in
            processManager.applyFiltersAndSort()
        }
        .onChange(of: processManager.currentFilter) { _ in
            processManager.applyFiltersAndSort()
        }
        .onChange(of: processManager.currentSort) { _ in
            processManager.applyFiltersAndSort()
        }
        .onChange(of: processManager.sortAscending) { _ in
            processManager.applyFiltersAndSort()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Processes")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Statistics
                HStack(spacing: 20) {
                    StatBadge(label: "Total", value: "\(processManager.totalProcessCount)")
                    StatBadge(label: "User", value: "\(processManager.userProcessCount)", color: .blue)
                    StatBadge(label: "System", value: "\(processManager.systemProcessCount)", color: .orange)
                    StatBadge(label: "Memory", value: ByteCountFormatter.string(fromByteCount: processManager.totalMemoryUsage, countStyle: .memory))
                    StatBadge(label: "CPU", value: String(format: "%.1f%%", processManager.totalCPUUsage), color: .green)
                }
            }
            
            // Controls
            HStack {
                // Auto-refresh toggle
                Toggle("Auto-refresh", isOn: Binding(
                    get: { processManager.isMonitoring },
                    set: { enabled in
                        if enabled {
                            processManager.startMonitoring()
                        } else {
                            processManager.stopMonitoring()
                        }
                    }
                ))
                .toggleStyle(.switch)
                
                if processManager.isMonitoring {
                    // Refresh interval
                    HStack(spacing: 4) {
                        Text("Interval:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("", selection: $processManager.refreshInterval) {
                            Text("1s").tag(1.0)
                            Text("2s").tag(2.0)
                            Text("5s").tag(5.0)
                            Text("10s").tag(10.0)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60)
                    }
                }
                
                Spacer()
                
                // Refresh button
                Button {
                    Task {
                        await processManager.refreshProcesses()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(GlassButton())
                .disabled(processManager.isLoading)
            }
        }
        .padding()
        .glassBackground()
        .padding()
    }
    
    // MARK: - Toolbar View
    
    private var toolbarView: some View {
        HStack(spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search processes...", text: $processManager.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .frame(maxWidth: 300)
            
            // Filter
            Picker("Filter", selection: $processManager.currentFilter) {
                ForEach(ProcessFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            
            // Sort
            Picker("Sort", selection: $processManager.currentSort) {
                ForEach(ProcessSortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 100)
            
            // Sort direction
            Button {
                processManager.sortAscending.toggle()
            } label: {
                Image(systemName: processManager.sortAscending ? "arrow.up" : "arrow.down")
            }
            .buttonStyle(.plain)
            .help(processManager.sortAscending ? "Ascending" : "Descending")
            
            Spacer()
            
            // Detail panel toggle
            Button {
                withAnimation {
                    showDetailPanel.toggle()
                    if !showDetailPanel {
                        selectedProcess = nil
                    }
                }
            } label: {
                Image(systemName: showDetailPanel ? "sidebar.right" : "sidebar.trailing")
            }
            .buttonStyle(GlassButton())
            .help("Toggle detail panel")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .glassBackground()
        .padding(.horizontal)
    }
    
    // MARK: - Process List View
    
    private var processListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if processManager.isLoading && processManager.processes.isEmpty {
                    ProgressView()
                        .padding()
                } else if processManager.filteredProcesses.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No processes found")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ForEach(processManager.filteredProcesses) { process in
                        ProcessRowView(
                            process: process,
                            onKill: {
                                try? processManager.killProcess(process)
                            },
                            onForceQuit: {
                                processManager.forceQuitProcess(process)
                            },
                            onShowInFinder: {
                                processManager.showInFinder(process)
                            }
                        )
                        .onTapGesture {
                            selectedProcess = process
                            if !showDetailPanel {
                                showDetailPanel = true
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let label: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(6)
    }
}





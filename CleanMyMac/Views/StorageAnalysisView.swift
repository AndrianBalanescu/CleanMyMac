//
//  StorageAnalysisView.swift
//  CleanMyMac
//
//  Storage breakdown and visualization
//

import SwiftUI

struct StorageAnalysisView: View {
    @StateObject private var analyzer = StorageAnalyzer()
    @State private var selectedCategory: StorageItem.StorageCategory?
    @State private var showDirectorySelection = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Storage Analysis")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let breakdown = analyzer.breakdown {
                        Text("Total: \(breakdown.displayTotalSize)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(analyzer.selectedDirectories.count) directory\(analyzer.selectedDirectories.count == 1 ? "" : "ies") selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Select Directories") {
                        showDirectorySelection.toggle()
                    }
                    .buttonStyle(GlassButton())
                    
                    if analyzer.isLoading {
                        Button("Cancel") {
                            analyzer.cancelScan()
                        }
                        .buttonStyle(GlassButton())
                        .foregroundColor(.red)
                    } else {
                        Button("Analyze") {
                            Task {
                                await analyzer.analyzeStorage()
                            }
                        }
                        .buttonStyle(GlassButton())
                        .disabled(analyzer.selectedDirectories.isEmpty)
                    }
                }
            }
            .padding()
            .glassBackground()
            .padding()
            
            // Directory Selection Sheet
            .sheet(isPresented: $showDirectorySelection) {
                DirectorySelectionView(analyzer: analyzer)
                    .frame(minWidth: 600, minHeight: 500)
            }
            
            if analyzer.isLoading {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView(value: analyzer.progressValue)
                        .progressViewStyle(.linear)
                    Text(analyzer.progressMessage.isEmpty ? "Analyzing storage..." : analyzer.progressMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("This may take a few moments. Large directories are skipped.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 400)
                Spacer()
            } else if let breakdown = analyzer.breakdown {
                ScrollView {
                    VStack(spacing: 20) {
                        // Storage by Category
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Storage by Category")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            ForEach(Array(breakdown.byCategory.keys.sorted { 
                                breakdown.byCategory[$0] ?? 0 > breakdown.byCategory[$1] ?? 0 
                            }), id: \.self) { category in
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
                        
                        // Large Files
                        if !breakdown.largeFiles.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Largest Files")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                ForEach(breakdown.largeFiles.prefix(20)) { file in
                                    HStack {
                                        Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                                            .foregroundColor(.secondary)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(file.name)
                                                .font(.headline)
                                            Text(file.path)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(file.displaySize)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .glassBackground()
                                }
                            }
                            .padding()
                            .glassBackground()
                        }
                        
                        // Old Files
                        if !breakdown.oldFiles.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Old Files (90+ days)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                ForEach(breakdown.oldFiles.prefix(20)) { file in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(file.name)
                                                .font(.headline)
                                            if let days = file.daysSinceAccessed {
                                                Text("Not accessed in \(days) days")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Text(file.displaySize)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .glassBackground()
                                }
                            }
                            .padding()
                            .glassBackground()
                        }
                    }
                    .padding()
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Selected Directories Info
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Selected Directories")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(analyzer.selectedDirectories.count) selected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if analyzer.selectedDirectories.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.title)
                                        .foregroundColor(.secondary)
                                    Text("No directories selected")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Click 'Select Directories' to choose which folders to scan")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            } else {
                                ForEach(analyzer.availableDirectories.filter { analyzer.selectedDirectories.contains($0.path) }, id: \.path) { directory in
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(directory.name)
                                                .font(.headline)
                                            Text(directory.path)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .glassBackground()
                                }
                            }
                        }
                        .padding()
                        .glassBackground()
                        
                        // Instructions
                        if !analyzer.selectedDirectories.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Ready to Scan")
                                    .font(.headline)
                                Text("Click 'Analyze' to start scanning the selected directories. macOS may ask for permission to access each folder - you can allow or deny access as needed.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .glassBackground()
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            // Don't auto-scan - user must click button
        }
    }
}

struct StorageCategoryRow: View {
    let category: StorageItem.StorageCategory
    let size: Int64
    let totalSize: Int64
    
    var percentage: Double {
        guard totalSize > 0 else { return 0 }
        return Double(size) / Double(totalSize) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.rawValue)
                    .font(.headline)
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .glassBackground()
    }
}


//
//  DirectorySelectionView.swift
//  CleanMyMac
//
//  Directory selection for storage scanning
//

import SwiftUI

struct DirectorySelectionView: View {
    @ObservedObject var analyzer: StorageAnalyzer
    @Environment(\.dismiss) private var dismiss
    @State private var tempSelections: Set<String>
    @State private var showAccessibilityInfo = false
    
    init(analyzer: StorageAnalyzer) {
        self.analyzer = analyzer
        _tempSelections = State(initialValue: analyzer.selectedDirectories)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Select directories to scan")
                            .font(.headline)
                        Spacer()
                        Button {
                            showAccessibilityInfo.toggle()
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    Text("Check the directories you want to analyze. macOS may ask for permission when you start scanning.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if showAccessibilityInfo {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Note:")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("• Permissions are requested only when you click 'Analyze'")
                            Text("• You can grant or deny access for each folder")
                            Text("• System directories may require Full Disk Access")
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassBackground()
                
                // Directory List
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(analyzer.availableDirectories, id: \.path) { directory in
                            HStack(spacing: 12) {
                                Toggle("", isOn: Binding(
                                    get: { tempSelections.contains(directory.path) },
                                    set: { isOn in
                                        if isOn {
                                            tempSelections.insert(directory.path)
                                        } else {
                                            tempSelections.remove(directory.path)
                                        }
                                    }
                                ))
                                .toggleStyle(.checkbox)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(directory.name)
                                        .font(.headline)
                                    Text(directory.path)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "folder.fill")
                                    .foregroundColor(tempSelections.contains(directory.path) ? .blue : .gray)
                            }
                            .padding()
                            .glassBackground()
                        }
                    }
                    .padding()
                }
                
                // Actions
                HStack(spacing: 12) {
                    Button("Select All") {
                        tempSelections = Set(analyzer.availableDirectories.map { $0.path })
                    }
                    .buttonStyle(GlassButton())
                    
                    Button("Deselect All") {
                        tempSelections.removeAll()
                    }
                    .buttonStyle(GlassButton())
                    
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(GlassButton())
                    
                    Button("Apply") {
                        analyzer.selectedDirectories = tempSelections
                        dismiss()
                    }
                    .buttonStyle(GlassButton())
                    .disabled(tempSelections.isEmpty)
                }
                .padding()
                .glassBackground()
            }
            .navigationTitle("Select Directories to Scan")
            .frame(minWidth: 600, minHeight: 500)
        }
    }
}


//
//  TrashCleanupView.swift
//  CleanMyMac
//
//  Trash file management
//

import SwiftUI

struct TrashCleanupView: View {
    @StateObject private var trashManager = TrashManager()
    @State private var showEmptyTrashAlert = false
    @State private var showDeleteItemAlert = false
    @State private var itemToDelete: TrashItem?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trash")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if trashManager.trashItems.isEmpty && !trashManager.isLoading {
                        Text("Click 'Scan Trash' to see trash contents")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(trashManager.trashItems.count) items • \(trashManager.displayTotalSize)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if trashManager.trashItems.isEmpty && !trashManager.isLoading {
                        Button("Scan Trash") {
                            Task {
                                await trashManager.scanTrash()
                            }
                        }
                        .buttonStyle(GlassButton())
                    }
                    
                    if !trashManager.trashItems.isEmpty {
                        Button("Empty Trash") {
                            showEmptyTrashAlert = true
                        }
                        .buttonStyle(GlassButton())
                        .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .glassBackground()
            .padding()
            
            // Trash Items List
            if trashManager.isLoading {
                Spacer()
                ProgressView("Scanning trash...")
                Spacer()
            } else if trashManager.trashItems.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Trash is empty")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(trashManager.trashItems) { item in
                            HStack(spacing: 16) {
                                // File Icon
                                Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                    .frame(width: 32)
                                
                                // File Info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                    
                                    HStack {
                                        Text(item.displaySize)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("•")
                                            .foregroundColor(.secondary)
                                        Text(item.formattedDate)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                // Delete Button
                                Button {
                                    itemToDelete = item
                                    showDeleteItemAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
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
        .alert("Empty Trash", isPresented: $showEmptyTrashAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Empty", role: .destructive) {
                Task {
                    try? await trashManager.emptyTrash()
                }
            }
        } message: {
            Text("Are you sure you want to permanently delete all \(trashManager.trashItems.count) items in the trash? This action cannot be undone.")
        }
        .alert("Delete Item", isPresented: $showDeleteItemAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    try? trashManager.deleteItem(item)
                }
            }
        } message: {
            if let item = itemToDelete {
                Text("Are you sure you want to permanently delete \"\(item.name)\"? This action cannot be undone.")
            }
        }
    }
}


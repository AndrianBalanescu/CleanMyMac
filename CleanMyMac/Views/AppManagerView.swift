//
//  AppManagerView.swift
//  CleanMyMac
//
//  App management interface
//

import SwiftUI

struct AppManagerView: View {
    @StateObject private var appManager = AppManager()
    @State private var searchText = ""
    @State private var showUninstallAlert = false
    @State private var appToUninstall: InstalledApp?
    
    var filteredApps: [InstalledApp] {
        if searchText.isEmpty {
            return appManager.installedApps
        }
        return appManager.installedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        HSplitView {
            // App List
            VStack(spacing: 0) {
                // Header with Scan Button
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search apps...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding()
                    .glassBackground()
                    
                    if !appManager.isLoading && appManager.installedApps.isEmpty {
                        VStack(spacing: 8) {
                            Text("No apps scanned yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Button("Scan Applications") {
                                Task {
                                    await appManager.scanInstalledApps()
                                }
                            }
                            .buttonStyle(GlassButton())
                            Text("This will scan /Applications and ~/Applications folders")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .padding()
                
                // App List
                if appManager.isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Scanning applications...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("This may take a moment")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if !appManager.installedApps.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredApps) { app in
                                AppListItemView(
                                    app: app,
                                    isSelected: appManager.selectedApp?.id == app.id
                                ) {
                                    Task {
                                        await appManager.selectApp(app)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .frame(minWidth: 300, idealWidth: 350)
            .glassBackground(material: .thinMaterial)
            
            // App Details
            if let selectedApp = appManager.selectedApp {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // App Header
                        HStack(spacing: 16) {
                            if let icon = selectedApp.iconImage {
                                Image(nsImage: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 64, height: 64)
                                    .cornerRadius(12)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedApp.name)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("Version \(selectedApp.version)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Size: \(selectedApp.displaySize)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Uninstall") {
                                appToUninstall = selectedApp
                                showUninstallAlert = true
                            }
                            .buttonStyle(GlassButton())
                            .foregroundColor(.red)
                        }
                        .padding()
                        .glassBackground()
                        
                        // Caches Section
                        if !appManager.appCaches.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Caches")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("\(appManager.appCaches.count) locations")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                ForEach(appManager.appCaches) { cache in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(cache.path)
                                                .font(.system(.body, design: .monospaced))
                                                .lineLimit(1)
                                            
                                            HStack {
                                                Text(cache.displaySize)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text("•")
                                                    .foregroundColor(.secondary)
                                                Text("\(cache.fileCount) files")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            try? appManager.deleteCache(cache)
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
                        
                        // Leftover Files Section
                        if !appManager.leftoverFiles.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Leftover Files")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("\(appManager.leftoverFiles.count) files")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                ForEach(appManager.leftoverFiles, id: \.self) { path in
                                    HStack {
                                        Text(path)
                                            .font(.system(.body, design: .monospaced))
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        Button {
                                            try? appManager.deleteLeftoverFile(at: path)
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
                        
                        // Enhanced Metadata Section
                        if let metadata = selectedApp.metadata {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("App Information")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                if let installDate = metadata.formattedInstallationDate {
                                    InfoRow(label: "Installed", value: installDate)
                                }
                                
                                if let lastUsed = metadata.formattedLastUsedDate {
                                    InfoRow(label: "Last Used", value: lastUsed)
                                    if let days = metadata.daysSinceLastUsed {
                                        Text("\(days) days ago")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if let category = metadata.category {
                                    InfoRow(label: "Category", value: category.rawValue)
                                }
                                
                                if let developer = metadata.developer {
                                    InfoRow(label: "Developer", value: developer)
                                }
                                
                                if metadata.isAppStoreApp {
                                    HStack {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.blue)
                                        Text("App Store App")
                                            .font(.subheadline)
                                    }
                                }
                                
                                if !metadata.permissions.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Permissions")
                                            .font(.headline)
                                        ForEach(metadata.permissions, id: \.self) { permission in
                                            Text("• \(permission)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .glassBackground()
                        }
                        
                        // CLI Tools Section
                        if !selectedApp.cliTools.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("CLI Tools")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                ForEach(selectedApp.cliTools) { tool in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(tool.name)
                                                .font(.headline)
                                            Text(tool.path)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                            if tool.isSymlink, let target = tool.symlinkTarget {
                                                Text("→ \(target)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Text(tool.displaySize)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .glassBackground()
                                }
                            }
                            .padding()
                        }
                        
                        // Keyboard Shortcuts Section
                        if !selectedApp.keyboardShortcuts.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Keyboard Shortcuts")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                ForEach(selectedApp.keyboardShortcuts) { shortcut in
                                    HStack {
                                        Text(shortcut.displayString)
                                            .font(.system(.body, design: .monospaced))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(4)
                                        
                                        Spacer()
                                        
                                        Text(shortcut.action)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .glassBackground()
                                }
                            }
                            .padding()
                        }
                        
                        if appManager.appCaches.isEmpty && appManager.leftoverFiles.isEmpty && selectedApp.metadata == nil && selectedApp.cliTools.isEmpty && selectedApp.keyboardShortcuts.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)
                                Text("No additional information found")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select an app to view details")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            // Don't auto-scan - user must click button
        }
        .alert("Uninstall App", isPresented: $showUninstallAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Uninstall", role: .destructive) {
                if let app = appToUninstall {
                    Task {
                        try? await appManager.uninstallApp(app)
                    }
                }
            }
        } message: {
            if let app = appToUninstall {
                Text("Are you sure you want to uninstall \(app.name)? This will also remove associated caches and leftover files.")
            }
        }
    }
}


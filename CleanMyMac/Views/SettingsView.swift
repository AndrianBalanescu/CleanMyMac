//
//  SettingsView.swift
//  CleanMyMac
//
//  Settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = ScanSettings.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var showPermissionAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Permissions Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Permissions")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Full Disk Access")
                                    .font(.headline)
                                Text("Required to scan applications and system files")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if permissionManager.hasFullDiskAccess {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Granted")
                                        .foregroundColor(.green)
                                }
                            } else {
                                Button("Grant Permission") {
                                    permissionManager.requestFullDiskAccess()
                                }
                                .buttonStyle(GlassButton())
                            }
                        }
                        .padding()
                        .glassBackground()
                    }
                }
                .padding()
                .glassBackground()
                
                // Scan Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Scan Options")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Auto-start System Monitoring", isOn: $settings.autoStartMonitoring)
                            .onChange(of: settings.autoStartMonitoring) { _ in
                                settings.saveSettings()
                            }
                        
                        Text("When enabled, system monitoring will start automatically when you open the Dashboard")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .glassBackground()
                }
                .padding()
                .glassBackground()
                
                // About
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MyMac v1.0")
                            .font(.headline)
                        Text("A comprehensive macOS management tool")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("All scanning is opt-in. Nothing is scanned automatically unless you explicitly start a scan.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding()
                    .glassBackground()
                }
                .padding()
                .glassBackground()
            }
            .padding()
        }
    }
}


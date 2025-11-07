//
//  MainView.swift
//  CleanMyMac
//
//  Primary container with sidebar navigation
//

import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case apps = "Apps"
    case trash = "Trash"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .apps:
            return "app.badge"
        case .trash:
            return "trash"
        }
    }
}

struct MainView: View {
    @State private var selectedItem: NavigationItem = .apps
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedItem) {
                ForEach(NavigationItem.allCases) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("CleanMyMac")
            .frame(minWidth: 200)
            .glassBackground(material: .thinMaterial)
        } detail: {
            // Content
            Group {
                switch selectedItem {
                case .apps:
                    AppManagerView()
                case .trash:
                    TrashCleanupView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.ultraThinMaterial)
        .onAppear {
            checkPermissions()
        }
        .alert("Permissions Required", isPresented: .constant(!permissionManager.hasFullDiskAccess && selectedItem == .apps)) {
            Button("Open System Settings") {
                permissionManager.requestFullDiskAccess()
            }
            Button("Later", role: .cancel) { }
        } message: {
            Text("Full Disk Access is required to scan applications and manage files. Please grant permission in System Settings.")
        }
    }
    
    private func checkPermissions() {
        permissionManager.checkFullDiskAccess()
    }
}


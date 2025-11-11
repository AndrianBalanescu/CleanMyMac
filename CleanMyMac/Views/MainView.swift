//
//  MainView.swift
//  CleanMyMac
//
//  Primary container with sidebar navigation
//

import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case apps = "Apps"
    case storage = "Storage"
    case system = "System"
    case processes = "Processes"
    case network = "Network"
    case trash = "Trash"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard:
            return "chart.bar.fill"
        case .apps:
            return "app.badge"
        case .storage:
            return "externaldrive.fill"
        case .system:
            return "cpu"
        case .processes:
            return "list.bullet.rectangle"
        case .network:
            return "network"
        case .trash:
            return "trash"
        case .settings:
            return "gearshape.fill"
        }
    }
}

struct MainView: View {
    @State private var selectedItem: NavigationItem = .dashboard
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
            .navigationTitle("MyMac")
            .frame(minWidth: 200)
            .glassBackground(material: .thinMaterial)
        } detail: {
            // Content
            Group {
                switch selectedItem {
                case .dashboard:
                    DashboardView()
                case .apps:
                    AppManagerView()
                case .storage:
                    StorageAnalysisView()
                case .system:
                    SystemMonitorView()
                case .processes:
                    ProcessView()
                case .network:
                    NetworkMonitorView()
                case .trash:
                    TrashCleanupView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.ultraThinMaterial)
        .onAppear {
            // Don't check permissions automatically - let user request when needed
        }
    }
    
    private func checkPermissions() {
        permissionManager.checkFullDiskAccess()
    }
}


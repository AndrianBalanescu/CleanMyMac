//
//  NetworkMonitorView.swift
//  CleanMyMac
//
//  Network activity monitoring
//

import SwiftUI

struct NetworkMonitorView: View {
    @StateObject private var monitor = NetworkMonitor()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Network Monitor")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                if monitor.connections.isEmpty && !monitor.isLoading {
                    Button("Scan Network") {
                        Task {
                            await monitor.scanConnections()
                        }
                    }
                    .buttonStyle(GlassButton())
                } else {
                    Button("Refresh") {
                        Task {
                            await monitor.scanConnections()
                        }
                    }
                    .buttonStyle(GlassButton())
                }
            }
            .padding()
            .glassBackground()
            .padding()
            
            if monitor.isLoading {
                Spacer()
                ProgressView("Scanning network connections...")
                Spacer()
            } else if monitor.connections.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "network")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("No network connections found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(monitor.connections.prefix(50)) { connection in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(connection.processName)
                                        .font(.headline)
                                    Text("\(connection.localAddress):\(connection.localPort)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if !connection.remoteAddress.isEmpty {
                                        Text("→ \(connection.remoteAddress):\(connection.remotePort)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(connection.`protocol`.uppercased())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(connection.state)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
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


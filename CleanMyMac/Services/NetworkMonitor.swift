//
//  NetworkMonitor.swift
//  CleanMyMac
//
//  Monitor network activity
//

import Foundation

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var connections: [NetworkConnection] = []
    @Published var isLoading = false
    
    func scanConnections() async {
        isLoading = true
        defer { isLoading = false }
        
        // Run network scan on background thread
        let connectionList = await Task.detached(priority: .userInitiated) {
            var connections: [NetworkConnection] = []
            
            // Use netstat to get network connections
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
            process.arguments = ["-an"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe() // Suppress errors
            
            do {
                try process.run()
                
                // Wait with timeout to prevent hanging
                let timeoutTask = Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                    if process.isRunning {
                        process.terminate()
                    }
                }
                
                process.waitUntilExit()
                timeoutTask.cancel()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                let lines = output.components(separatedBy: "\n")
                // Limit to first 1000 connections to prevent UI freeze
                let maxLines = min(lines.count, 1002) // +2 for headers
                
                for line in lines.dropFirst(2).prefix(maxLines - 2) {
                    let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    
                    if components.count >= 4 {
                        let protocolName = components[0]
                        let local = components[3]
                        let state = components.count > 4 ? components[4] : ""
                        
                        // Parse local address:port (handle IPv4 and IPv6)
                        var address = ""
                        var port = 0
                        
                        if local.contains(".") {
                            // IPv4
                            let localParts = local.components(separatedBy: ".")
                            if localParts.count >= 2 {
                                address = localParts.dropLast().joined(separator: ".")
                                port = Int(localParts.last ?? "0") ?? 0
                            }
                        } else if local.contains(":") {
                            // IPv6 - just use the port part
                            let parts = local.components(separatedBy: ":")
                            if let lastPart = parts.last {
                                port = Int(lastPart) ?? 0
                            }
                            address = local
                        }
                        
                        if !address.isEmpty {
                            let connection = NetworkConnection(
                                processName: "Unknown",
                                processPID: 0,
                                localAddress: address,
                                localPort: port,
                                remoteAddress: "",
                                remotePort: 0,
                                protocol: protocolName,
                                state: state
                            )
                            
                            connections.append(connection)
                        }
                    }
                }
            } catch {
                // Error handling - return empty list
            }
            
            return connections
        }.value
        
        await MainActor.run {
            connections = connectionList
        }
    }
}


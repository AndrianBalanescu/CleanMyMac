//
//  NetworkConnection.swift
//  CleanMyMac
//
//  Network connection data
//

import Foundation

struct NetworkConnection: Identifiable, Codable {
    let id: String
    let processName: String
    let processPID: Int32
    let localAddress: String
    let localPort: Int
    let remoteAddress: String
    let remotePort: Int
    let `protocol`: String
    let state: String
    let bytesIn: Int64
    let bytesOut: Int64
    
    init(id: String = UUID().uuidString,
         processName: String,
         processPID: Int32,
         localAddress: String,
         localPort: Int,
         remoteAddress: String,
         remotePort: Int,
         protocol: String,
         state: String,
         bytesIn: Int64 = 0,
         bytesOut: Int64 = 0) {
        self.id = id
        self.processName = processName
        self.processPID = processPID
        self.localAddress = localAddress
        self.localPort = localPort
        self.remoteAddress = remoteAddress
        self.remotePort = remotePort
        self.`protocol` = `protocol`
        self.state = state
        self.bytesIn = bytesIn
        self.bytesOut = bytesOut
    }
}


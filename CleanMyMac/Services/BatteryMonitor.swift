//
//  BatteryMonitor.swift
//  CleanMyMac
//
//  Monitor battery (MacBook)
//

import Foundation
import IOKit
import IOKit.ps

@MainActor
class BatteryMonitor: ObservableObject {
    @Published var cycleCount: Int?
    @Published var maxCapacity: Int?
    @Published var currentCapacity: Int?
    @Published var condition: String?
    @Published var isCharging: Bool = false
    @Published var timeRemaining: Int? // Minutes
    
    func refreshBatteryInfo() async {
        // Check if device has battery (MacBook)
        let hasBattery = await checkHasBattery()
        
        if !hasBattery {
            return // Not a MacBook
        }
        
        // Get battery info using IOKit
        // This is a simplified version - full implementation would use IOPowerSources API
        
        // Use pmset for battery info
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "batt"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            // Parse battery info
            if output.contains("AC Power") {
                isCharging = true
            } else if output.contains("Battery Power") {
                isCharging = false
            }
            
            // Extract percentage
            if let percentRange = output.range(of: "\\d+%", options: .regularExpression) {
                let percentString = String(output[percentRange])
                let percent = Int(percentString.replacingOccurrences(of: "%", with: ""))
                currentCapacity = percent
            }
        } catch {
            // Error handling
        }
        
        // Get cycle count from system_profiler
        await getCycleCount()
    }
    
    private func checkHasBattery() async -> Bool {
        // Check if system has battery
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPPowerDataType"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return output.contains("Battery Information")
        } catch {
            return false
        }
    }
    
    private func getCycleCount() async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPPowerDataType"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            // Parse cycle count
            if let cycleRange = output.range(of: "Cycle Count: \\d+", options: .regularExpression) {
                let cycleString = String(output[cycleRange])
                let components = cycleString.components(separatedBy: ":")
                if components.count > 1 {
                    cycleCount = Int(components[1].trimmingCharacters(in: .whitespaces))
                }
            }
            
            // Parse condition
            if let conditionRange = output.range(of: "Condition: \\w+", options: .regularExpression) {
                let conditionString = String(output[conditionRange])
                let components = conditionString.components(separatedBy: ":")
                if components.count > 1 {
                    condition = components[1].trimmingCharacters(in: .whitespaces)
                }
            }
        } catch {
            // Error handling
        }
    }
}


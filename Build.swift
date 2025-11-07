#!/usr/bin/env swift

// CleanMyMac Build Script
// Swift-based build script for macOS app

import Foundation

let projectName = "CleanMyMac"
let schemeName = "CleanMyMac"
let buildDir = "build"
let configuration = "Release"
let productName = "CleanMyMac.app"

enum BuildError: Error {
    case xcodebuildNotFound
    case xcodegenNotFound
    case projectNotFound
    case buildFailed
    case projectGenerationFailed
}

func printInfo(_ message: String) {
    print("\u{001B}[32m[INFO]\u{001B}[0m \(message)")
}

func printWarn(_ message: String) {
    print("\u{001B}[33m[WARN]\u{001B}[0m \(message)")
}

func printError(_ message: String) {
    print("\u{001B}[31m[ERROR]\u{001B}[0m \(message)")
}

func checkCommand(_ command: String) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    process.arguments = [command]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    
    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    } catch {
        return false
    }
}

@discardableResult
func runCommand(_ command: String, arguments: [String] = []) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: command)
    process.arguments = arguments
    
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe
    
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus != 0 {
        let _ = errorPipe.fileHandleForReading.readDataToEndOfFile()
        throw BuildError.buildFailed
    }
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: outputData, encoding: .utf8) ?? ""
}

func generateProject() throws {
    printInfo("Generating Xcode project using xcodegen...")
    
    if !checkCommand("xcodegen") {
        printError("xcodegen not found. Please install it:")
        print("  brew install xcodegen")
        throw BuildError.xcodegenNotFound
    }
    
    if !FileManager.default.fileExists(atPath: "project.yml") {
        printError("project.yml not found. Please create it first.")
        throw BuildError.projectGenerationFailed
    }
    
    // Try to find xcodegen in common locations
    let xcodegenPaths = ["/usr/local/bin/xcodegen", "/opt/homebrew/bin/xcodegen", "/usr/bin/xcodegen"]
    var xcodegenPath: String?
    
    for path in xcodegenPaths {
        if FileManager.default.fileExists(atPath: path) {
            xcodegenPath = path
            break
        }
    }
    
    if let xcodegenPath = xcodegenPath {
        try runCommand(xcodegenPath, arguments: ["generate"])
    } else {
        // Try to find it via which
        let whichOutput = try runCommand("/usr/bin/which", arguments: ["xcodegen"])
        let path = whichOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !path.isEmpty {
            try runCommand(path, arguments: ["generate"])
        } else {
            throw BuildError.xcodegenNotFound
        }
    }
    printInfo("Project generated successfully")
}

func buildProject() throws -> String? {
    printInfo("Building \(projectName)...")
    
    let projectPath = "\(projectName).xcodeproj"
    
    if !FileManager.default.fileExists(atPath: projectPath) {
        printWarn("Xcode project not found. Generating...")
        try generateProject()
    }
    
    let arguments = [
        "-project", projectPath,
        "-scheme", schemeName,
        "-configuration", configuration,
        "-derivedDataPath", buildDir,
        "-destination", "platform=macOS",
        "CODE_SIGN_IDENTITY=",
        "CODE_SIGNING_REQUIRED=NO",
        "CODE_SIGNING_ALLOWED=NO",
        "-quiet" // Reduce output, but still show errors
    ]
    
    printInfo("Running xcodebuild...")
    try runCommand("/usr/bin/xcodebuild", arguments: arguments)
    printInfo("Build successful!")
    
    // Find the built app
    let fileManager = FileManager.default
    let enumerator = fileManager.enumerator(atPath: buildDir)
    
    var appPath: String?
    while let element = enumerator?.nextObject() as? String {
        if element.hasSuffix("\(productName)") {
            appPath = "\(buildDir)/\(element)"
            break
        }
    }
    
    if let appPath = appPath {
        printInfo("App built at: \(appPath)")
        return appPath
    } else {
        printWarn("Could not locate built app")
        return nil
    }
}

func cleanBuild() throws {
    printInfo("Cleaning build directory...")
    
    if FileManager.default.fileExists(atPath: buildDir) {
        try FileManager.default.removeItem(atPath: buildDir)
    }
    
    let projectPath = "\(projectName).xcodeproj"
    if FileManager.default.fileExists(atPath: projectPath) {
        let arguments = [
            "clean",
            "-project", projectPath,
            "-scheme", schemeName,
            "-configuration", configuration
        ]
        try runCommand("/usr/bin/xcodebuild", arguments: arguments)
    }
    
    printInfo("Clean completed")
}

func installApp(appPath: String) throws {
    let currentDir = FileManager.default.currentDirectoryPath
    let destination = "\(currentDir)/\(productName)"
    
    if FileManager.default.fileExists(atPath: destination) {
        try FileManager.default.removeItem(atPath: destination)
    }
    
    try FileManager.default.copyItem(atPath: appPath, toPath: destination)
    printInfo("App installed to: \(destination)")
}

func runApp(appPath: String) throws {
    printInfo("Running \(productName)...")
    
    // Ensure we have the full path to the .app bundle
    let fullPath = (appPath as NSString).expandingTildeInPath
    
    // Use open command with the app path
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = [fullPath]
    
    do {
        try process.run()
        process.waitUntilExit()
        
        // open command can succeed even with non-zero exit in some cases
        // Check if the app actually exists
        if FileManager.default.fileExists(atPath: fullPath) {
            printInfo("App launched successfully")
        } else {
            printError("App not found at: \(fullPath)")
            throw BuildError.buildFailed
        }
    } catch {
        printError("Failed to launch app: \(error.localizedDescription)")
        throw BuildError.buildFailed
    }
}

// Main execution
let arguments = CommandLine.arguments

guard !arguments.isEmpty else {
    print("Usage: swift Build.swift [clean|build|install|run]")
    exit(1)
}

do {
    // Check for xcodebuild
    if !checkCommand("xcodebuild") {
        printError("xcodebuild not found. Please install Xcode Command Line Tools:")
        print("  xcode-select --install")
        exit(1)
    }
    
    let command = arguments.count > 1 ? arguments[1] : "build"
    
    switch command {
    case "clean":
        try cleanBuild()
        
    case "build":
        let appPath = try buildProject()
        if appPath != nil {
            exit(0)
        } else {
            exit(1)
        }
        
    case "install":
        let appPath = try buildProject()
        if let appPath = appPath {
            try installApp(appPath: appPath)
        }
        
    case "run":
        let appPath = try buildProject()
        if let appPath = appPath {
            try runApp(appPath: appPath)
        }
        
    default:
        print("Unknown command: \(command)")
        print("Usage: swift Build.swift [clean|build|install|run]")
        exit(1)
    }
    
} catch BuildError.xcodebuildNotFound {
    printError("xcodebuild not found")
    exit(1)
} catch BuildError.xcodegenNotFound {
    printError("xcodegen not found")
    exit(1)
} catch BuildError.buildFailed {
    printError("Build failed")
    exit(1)
} catch {
    printError("Error: \(error)")
    exit(1)
}


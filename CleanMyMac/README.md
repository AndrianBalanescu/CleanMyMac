# CleanMyMac

A native macOS application built with SwiftUI for managing applications, cleaning caches, and managing trash files. Features a beautiful glass UI with translucent windows and vibrancy effects.

## Features

### App Management
- Scan and list all installed applications from `/Applications` and `~/Applications`
- View detailed app information (name, version, bundle ID, size)
- Display app icons
- Detect and manage app caches
- Find and remove leftover files from uninstalled apps
- Uninstall apps with automatic cleanup of associated files

### Trash Management
- List all files in the trash
- Display file sizes and deletion dates
- Empty trash functionality
- Delete individual items from trash

### Glass UI Design
- Modern translucent windows with vibrancy effects
- Beautiful glass morphism design using SwiftUI materials
- Smooth animations and transitions
- Native macOS design language

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later
- Swift 5.7 or later

## Project Structure

```
CleanMyMac/
├── CleanMyMacApp.swift          # App entry point
├── Info.plist                    # App configuration
├── Models/
│   ├── InstalledApp.swift       # App data model
│   ├── TrashItem.swift          # Trash file model
│   └── CacheLocation.swift      # Cache location model
├── Services/
│   ├── AppManager.swift         # App management service
│   ├── TrashManager.swift       # Trash management service
│   ├── FileSystemScanner.swift  # File system scanning
│   └── PermissionManager.swift  # macOS permissions
└── Views/
    ├── MainView.swift           # Main container with navigation
    ├── AppManagerView.swift     # App management interface
    ├── TrashCleanupView.swift   # Trash cleanup interface
    └── Components/
        ├── GlassBackgroundView.swift  # Glass UI components
        └── AppListItemView.swift      # App list item component
```

## Setup

1. Open the project in Xcode
2. Configure the bundle identifier in project settings
3. Build and run the application

## Permissions

The app requires Full Disk Access to:
- Scan installed applications
- Access application caches
- Find leftover files
- Manage trash files

You will be prompted to grant permissions when needed. The app will guide you to System Settings if permissions are not granted.

## Usage

### Managing Apps
1. Select "Apps" from the sidebar
2. Browse the list of installed applications
3. Click on an app to view details
4. View caches and leftover files associated with the app
5. Click "Uninstall" to remove the app and clean up associated files

### Managing Trash
1. Select "Trash" from the sidebar
2. View all items in the trash
3. Delete individual items or empty the entire trash

## Technical Details

- Built with SwiftUI for modern macOS development
- Uses async/await for file system operations
- Implements proper error handling for permission scenarios
- Uses NSWorkspace and FileManager for system operations
- Glass UI implemented using SwiftUI materials (ultraThinMaterial, thinMaterial)

## License

Copyright © 2024


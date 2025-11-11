# CleanMyMac
This is just an exploration project a good way to learn how SwiftUI and macOS system APIs work.
Learning Swift and native macOS development.


## What it does

A system management app with:
- Dashboard with system overview
- App management (scan, view, uninstall)
- Storage analysis
- System monitoring (CPU, memory, etc.)
- Process management
- Network monitoring
- Trash cleanup

The UI uses glass morphism effects with translucent windows - looks pretty nice.

## Tech stack

- Swift 5.7+
- SwiftUI
- macOS 13.0+
- Built with Xcode 14+

## Building

You'll need Xcode and optionally xcodegen:

```bash
# Install xcodegen (optional)
brew install xcodegen

# Build using make
make build

# Or use the Swift script
swift Build.swift build

# Or just use Xcode
xcodegen generate  # if needed
open CleanMyMac.xcodeproj
```

See [README_BUILD.md](README_BUILD.md) for more build options.

## Permissions

The app needs Full Disk Access to scan apps and manage files. You'll be prompted when needed, or grant it manually in System Settings → Privacy & Security → Full Disk Access.

## What I learned

This project helped me explore:
- SwiftUI basics (views, state, navigation)
- macOS system APIs (FileManager, NSWorkspace, process monitoring)
- Async/await in Swift
- Building native macOS UIs with materials and effects
- Organizing Swift code (MVVM, services)

## Project structure

```
CleanMyMac/
├── Models/          # Data models
├── Services/        # Business logic
├── Views/           # SwiftUI views
└── Components/      # Reusable UI components
```

## Disclaimer

This is a learning project. The code might have bugs, incomplete features, or experimental patterns. Use it as a reference, not in production.

## License

MIT License - see LICENSE file. Use it however you want for learning.

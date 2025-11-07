# Setup Instructions

## Creating the Xcode Project

1. Open Xcode
2. Select "Create a new Xcode project"
3. Choose "macOS" → "App"
4. Fill in the project details:
   - Product Name: `CleanMyMac`
   - Team: (Select your team)
   - Organization Identifier: (Your identifier)
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Minimum Deployment: `macOS 13.0`
5. Save the project in the workspace root directory
6. Delete the default `ContentView.swift` and `CleanMyMacApp.swift` files that Xcode creates
7. Add all the source files from the `CleanMyMac/` directory to your Xcode project:
   - Drag the `CleanMyMac` folder into Xcode
   - Make sure "Copy items if needed" is unchecked
   - Select "Create groups" (not folder references)
   - Add to target: `CleanMyMac`

## Project Configuration

1. In Xcode, select the project in the navigator
2. Go to the "Signing & Capabilities" tab
3. Ensure your team is selected for code signing
4. Go to "Info" tab and verify:
   - Minimum Deployments: macOS 13.0
   - Bundle Identifier matches your organization

## Build Settings

1. In Build Settings, search for "Swift Language Version"
2. Ensure it's set to Swift 5.7 or later
3. Search for "Deployment Target" and ensure it's set to macOS 13.0

## Info.plist Configuration

The `Info.plist` file is already configured with the necessary permissions. If you need to add it manually:

1. Right-click on the project
2. Select "New File" → "Property List"
3. Name it `Info.plist`
4. Copy the contents from the provided `Info.plist` file

## Running the App

1. Select the `CleanMyMac` scheme
2. Choose your Mac as the destination
3. Press Cmd+R to build and run

## Permissions

When you first run the app, you may need to grant Full Disk Access:

1. Go to System Settings → Privacy & Security → Full Disk Access
2. Click the "+" button
3. Navigate to your app and add it
4. Restart the app

## Troubleshooting

### "Cannot find 'MainView' in scope"
- Ensure all files are added to the Xcode project target
- Check that the file structure matches the directory structure
- Clean build folder (Cmd+Shift+K) and rebuild

### "@main attribute cannot be used"
- Ensure only one file has the `@main` attribute (CleanMyMacApp.swift)
- Check that there are no top-level statements in other files

### Window not translucent
- The translucent effect requires macOS 13.0+
- Ensure the deployment target is set correctly
- The window configuration happens automatically via the WindowModifier


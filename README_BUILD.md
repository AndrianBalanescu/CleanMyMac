# Build Instructions

This project provides multiple ways to build the app without using Xcode GUI.

## Option 1: Swift Build Script (Recommended)

The Swift-based build script (`Build.swift`) is the recommended approach as it's:
- Type-safe and easier to maintain
- Cross-platform compatible
- More readable than bash scripts

### Prerequisites

1. **Xcode Command Line Tools**:
   ```bash
   xcode-select --install
   ```

2. **xcodegen** (for project generation):
   ```bash
   brew install xcodegen
   ```

### Usage

```bash
# Build the app
swift Build.swift build

# Clean build directory
swift Build.swift clean

# Build and install (copy to current directory)
swift Build.swift install

# Build and run
swift Build.swift run
```

Or use the Makefile:
```bash
make build
make clean
make install
make run
```

## Option 2: Bash Script

The bash script (`build.sh`) provides the same functionality:

```bash
# Build the app
./build.sh

# Clean
./build.sh clean

# Build and install
./build.sh build install
```

## How It Works

1. **Project Generation**: If no Xcode project exists, the script uses `xcodegen` to generate one from `project.yml`
2. **Building**: Uses `xcodebuild` command-line tool to build the app
3. **Output**: The built app is placed in the `build/` directory

## Project Configuration

The `project.yml` file contains the Xcode project configuration. If you need to modify project settings, edit this file and regenerate:

```bash
xcodegen generate
```

Or just run the build script - it will auto-generate if needed.

## Troubleshooting

### "xcodebuild not found"
Install Xcode Command Line Tools:
```bash
xcode-select --install
```

### "xcodegen not found"
Install via Homebrew:
```bash
brew install xcodegen
```

### Build fails with code signing errors
The build script disables code signing by default. If you need to sign the app, modify the build script to include your signing identity.

### "Cannot find project"
The script will auto-generate the project if `project.yml` exists. Make sure `xcodegen` is installed.

## Manual Build (if scripts don't work)

If you prefer to build manually:

```bash
# Generate project
xcodegen generate

# Build
xcodebuild -project CleanMyMac.xcodeproj \
           -scheme CleanMyMac \
           -configuration Release \
           -derivedDataPath build \
           -destination "platform=macOS" \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO
```


#!/bin/bash

# CleanMyMac Build Script
# Builds the macOS app using xcodebuild without Xcode GUI

set -e

PROJECT_NAME="CleanMyMac"
SCHEME_NAME="CleanMyMac"
BUILD_DIR="build"
CONFIGURATION="Release"
PRODUCT_NAME="CleanMyMac.app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo_error "xcodebuild not found. Please install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    exit 1
fi

# Check if project exists
if [ ! -f "${PROJECT_NAME}.xcodeproj/project.pbxproj" ]; then
    echo_warn "Xcode project not found. Generating project..."
    
    # Check if xcodegen is available
    if command -v xcodegen &> /dev/null; then
        echo_info "Using xcodegen to generate project..."
        if [ ! -f "project.yml" ]; then
            echo_error "project.yml not found. Creating it..."
            create_project_yml
        fi
        xcodegen generate
    else
        echo_error "xcodegen not found. Please install it:"
        echo "  brew install xcodegen"
        echo ""
        echo "Or create the Xcode project manually in Xcode GUI first."
        exit 1
    fi
fi

# Clean previous build
if [ "$1" == "clean" ]; then
    echo_info "Cleaning build directory..."
    rm -rf "${BUILD_DIR}"
    xcodebuild clean -project "${PROJECT_NAME}.xcodeproj" -scheme "${SCHEME_NAME}" -configuration "${CONFIGURATION}"
    exit 0
fi

# Build the project
echo_info "Building ${PROJECT_NAME}..."
xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${BUILD_DIR}" \
    -destination "platform=macOS" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Check if build was successful
if [ $? -eq 0 ]; then
    echo_info "Build successful!"
    
    # Find the built app
    APP_PATH=$(find "${BUILD_DIR}" -name "${PRODUCT_NAME}" -type d | head -n 1)
    
    if [ -n "$APP_PATH" ]; then
        echo_info "App built at: ${APP_PATH}"
        
        # Copy to current directory if requested
        if [ "$1" == "install" ] || [ "$2" == "install" ]; then
            echo_info "Copying app to current directory..."
            cp -R "${APP_PATH}" .
            echo_info "App copied to: $(pwd)/${PRODUCT_NAME}"
        fi
    fi
else
    echo_error "Build failed!"
    exit 1
fi


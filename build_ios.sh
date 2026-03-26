#!/bin/bash

echo "Building iOS app without code signing..."

# Clean build directory
flutter clean

# Remove build artifacts
rm -rf build/
rm -rf ios/Pods/
rm -rf ios/.symlinks/

# Get dependencies
flutter pub get

# Install pods
cd ios
pod install
cd ..

# Clean native assets metadata (fix resource fork issue)
if [ -d "build/native_assets/ios" ]; then
    xattr -cr build/native_assets/ios/
    find build/native_assets/ios/ -name "._*" -delete 2>/dev/null || true
fi

# Build through Xcode command line (better at handling code signing)
xcodebuild -workspace ios/Runner.xcworkspace \
           -scheme Runner \
           -configuration Debug \
           -destination 'platform=iOS Simulator,name=iPhone 16e' \
           -allowProvisioningUpdates \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO \
           build

# If build succeeded, install and launch
if [ $? -eq 0 ]; then
    echo "Installing and launching app..."
    xcrun simctl install booted /Users/shahdhruvil/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphonesimulator/Runner.app
    xcrun simctl launch booted com.dhruvil.vayuxi123
    echo "App launched successfully!"
fi

echo "Build completed. Check above for any errors."

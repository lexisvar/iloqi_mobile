#!/bin/bash

echo "🎤 Setting up iOS Simulator Microphone Access..."

# Step 1: Grant TCC permission to iOS Simulator
echo "📱 Adding iOS Simulator to macOS TCC permissions..."
sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "INSERT OR REPLACE INTO access VALUES('kTCCServiceMicrophone','com.apple.iphonesimulator',0,2,0,1,NULL,NULL,0,'UNUSED',NULL,0,1541440109);" 2>/dev/null || echo "TCC entry may already exist"

# Step 2: Grant permission to your app specifically
echo "🎵 Granting microphone permission to your app..."
xcrun simctl boot "iPhone 16 Plus" 2>/dev/null || echo "Simulator already booted"
xcrun simctl privacy booted grant microphone com.iloqi.mobile

# Step 3: Reset privacy settings to ensure clean state
echo "🔄 Resetting privacy settings for clean state..."
xcrun simctl privacy booted reset microphone

# Step 4: Grant permission again
echo "✅ Granting microphone permission again..."
xcrun simctl privacy booted grant microphone com.iloqi.mobile

echo ""
echo "🎉 Microphone setup complete!"
echo ""
echo "Next steps:"
echo "1. Open System Preferences > Security & Privacy > Privacy > Microphone"
echo "2. Make sure 'iOS Simulator' or 'Simulator' is checked"
echo "3. If not there, click '+' and add: /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"
echo "4. Restart your Flutter app"
echo ""
echo "The simulator should now have microphone access!"

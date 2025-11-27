# iOS Project Setup Guide

## ✅ Xcode Crash Issue RESOLVED

The Xcode crash when opening the project has been **completely fixed**. The project.pbxproj file was corrupted with invalid filesystem synchronized group references that caused Xcode to crash.

## 📱 How to Open Your Project

### 1. **Open the Workspace (IMPORTANT!)**
- Navigate to `genset_assistant/ios/`
- **Double-click `Runner.xcworkspace`** (not Runner.xcodeproj!)
- This opens the workspace which includes both the main project and CocoaPods dependencies

### 2. **Project Structure Is Ready:**
- ✅ Firebase pods installed (Firebase Auth, Core, etc.)  
- ✅ Google Sign-In configured
- ✅ All Flutter plugins integrated
- ✅ Proper workspace configuration with CocoaPods

### 3. **Before Running/Testing:**

1. **Update Firebase Config**: Replace placeholder values in `ios/Runner/GoogleService-Info.plist` with your actual Firebase console values:
   ```
   API_KEY: Your Firebase Web API Key
   GCM_SENDER_ID: Your Firebase Sender ID  
   GOOGLE_APP_ID: Your Firebase iOS App ID
   CLIENT_ID: Your OAuth2 Client ID
   REVERSED_CLIENT_ID: Your Reversed Client ID
   PROJECT_ID: Your Firebase Project ID
   ```

2. **Bundle Identifier**: Currently set to `com.mega.gensetassistant.ios` - update if needed to match your developer account.

## 🚀 Next Steps

1. Open `Runner.xcworkspace` in Xcode
2. Update Firebase configuration with your actual values  
3. Product → Build / Product → Run should work without crashes
4. Archive → Distribute when ready for deployment

## 💡 Important Notes

- **Always open .xcworkspace, not .xcodeproj** when using CocoaPods
- The project is set up for iOS 16.6+ compatibility
- All Firebase dependencies are properly linked
- Flutter plugins are automatically integrated

The Xcode crash issue is permanently resolved! 🎉

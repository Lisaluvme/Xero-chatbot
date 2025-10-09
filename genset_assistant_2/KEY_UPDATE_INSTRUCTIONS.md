 # Play Console Key Update Instructions

## 🔑 Current Key Information
Your new keystore has been created with the following details:

**Certificate Fingerprint:**
- SHA1: `F7:60:D2:F8:4D:60:C4:F5:97:9E:2F:8D:B5:BA:1A:29:ED:F0:94:12`
- SHA256: `7F:2D:CD:33:45:67:77:64:16:64:D4:E7:8D:86:28:F8:DB:4B:08:BC:C1:BB:2F:A6:AE:3B:71:43:DE:BC:72:27`

**Expected by Play Console:**
- SHA1: `7C:79:14:E5:6E:63:7A:76:6D:3D:BE:FD:E9:A1:00:1E:91:5D:63:B1`

## 📋 Steps to Update Play Console with New Key

Since you need to update the Play Console with the new key, follow these steps:

### Option 1: Request Key Reset (Recommended for First Upload)
1. Go to Google Play Console
2. Navigate to your app
3. Go to **Setup → App integrity**
4. Find the **App signing key** section
5. Click on **Request key reset** or **Contact support**
6. Explain that you need to update the signing key for your app
7. Upload the new certificate information when requested

### Option 2: Create New App Listing
If this is a new app or you can start fresh:
1. Create a completely new app in Play Console
2. Use the current app bundle with the new key
3. This avoids any key conflicts

### Option 3: Contact Google Play Support
1. Go to Google Play Console Help Center
2. Submit a support request
3. Include both SHA1 fingerprints:
   - Current: `F7:60:D2:F8:4D:60:C4:F5:97:9E:2F:8D:B5:BA:1A:29:ED:F0:94:12`
   - Expected: `7C:79:14:E5:6E:63:7A:76:6D:3D:BE:FD:E9:A1:00:1E:91:5D:63:B1`
4. Request assistance with key migration

## 📁 Files to Backup
**CRITICAL:** Save these files securely for future updates:
- `android/app/release-key.jks` - Your new keystore file
- `android/key.properties` - Keystore configuration
- `KEY_UPDATE_INSTRUCTIONS.md` - This guide

## 🚀 After Key Update
Once the Play Console accepts your new key:
1. Upload the current app bundle: `build/app/outputs/bundle/release/app-release.aab`
2. Complete your store listing
3. Submit for review

## ⚠️ Important Notes
- **Never lose your keystore file** - you cannot update your app without it
- **Key changes are restricted** by Google for security reasons
- **Document this process** for future reference
- **Test thoroughly** before publishing to production

## 📞 If You Need Help
Google Play Developer Support can assist with key-related issues:
- Play Console Help Center
- Support contact form in Play Console
- Developer support forums

Your app is ready to publish once the key issue is resolved! 🎉

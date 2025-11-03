# Genset Assistant - Configuration System

This document explains how to use the local backend API configuration system for the Genset Assistant Flutter app.

## Overview

The app now supports multiple environments (Local, Staging, Production) with easy configuration switching and **SmartGen API caching**. This allows developers to seamlessly switch between different backend services without code changes, while providing fast, cached access to genset data.

## 🚀 Physical Device Backend Configuration

### Problem
When running Flutter apps on physical Android/iOS devices, `localhost` points to the device itself, not your development computer. This causes backend connection failures with errors like:
```
Network connection failed. Please check:
• Is the backend server running?
• Is your device connected to the same network?
• Is the backend URL correct? (http://localhost:3002/)
```

### Solution
The app automatically detects when running on physical devices and uses your computer's IP address instead of `localhost`.

### Automatic Detection
```dart
// The app automatically detects device type:
if (Platform.isAndroid || Platform.isIOS) {
  // Uses: http://192.168.50.241:3002/ (your computer's IP)
} else {
  // Uses: http://localhost:3002/ (for desktop/emulators)
}
```

### Current Configuration
- **Desktop/Emulator**: `http://localhost:3002/`
- **Physical Devices**: `http://192.168.50.241:3002/`
- **Port**: 3002 (matches your local backend server)

### Setup Steps

1. **Find Your Computer's IP Address**:
   ```bash
   # Windows (Command Prompt)
   ipconfig

   # Windows (PowerShell)
   Get-NetIPAddress | Where-Object {$_.AddressFamily -eq "IPv4" -and $_.IPAddress -notlike "127.*"}

   # Linux/Mac
   ifconfig | grep inet
   # or
   ip addr show
   ```

2. **Update Configuration** (if needed):
   - Open `lib/services/api_config.dart`
   - Update `_alternativeLocalUrl` with your IP:
   ```dart
   static const String _alternativeLocalUrl = 'http://YOUR_IP_HERE:3002/';
   ```

3. **Start Your Backend Server**:
   ```bash
   cd "C:\Users\tm\Documents\AI\Local Api Backend"
   npm install
   npm start
   ```

4. **Verify Server Access**:
   - Desktop: Open `http://localhost:3002/`
   - Mobile: Open `http://YOUR_IP:3002/` on your phone's browser

5. **Test the App**:
   - Run on physical device
   - Check console logs for correct URL usage
   - Gensets should now sync to Airtable successfully

### Console Output Examples
```
📱 Running on mobile device, using computer IP: http://192.168.50.241:3002/
🌐 Using backend URL: http://192.168.50.241:3002/
🔄 Syncing 10 gensets to Airtable in background...
✅ Successfully synced 10/10 gensets to Airtable
```

### Troubleshooting

1. **"Connection refused" on device**:
   - Verify your computer's IP address is correct
   - Ensure phone and computer are on same Wi-Fi network
   - Check firewall settings (allow port 3002)

2. **Server not accessible**:
   - Start backend server: `npm start`
   - Test from desktop: `http://localhost:3002/`
   - Test from phone: `http://YOUR_IP:3002/`

3. **Wrong IP detected**:
   - Some networks have multiple IP ranges
   - Use the IP that your phone can access
   - Update `_alternativeLocalUrl` manually if needed

### IP Detection Helper
The app includes a helper method to detect your network IP:
```dart
// Call this to see your detected IP
await ApiConfig.updateNetworkIP();
```
Check console logs for output like:
```
🔍 Detected network IP: 192.168.50.241
💡 Update _alternativeLocalUrl to: http://192.168.50.241:3002/
```

### Network Requirements
- Computer and mobile device must be on the same Wi-Fi network
- Backend server must be accessible on port 3002
- Firewall should allow connections on port 3002
- No VPN interference (or ensure VPN allows local network access)

## SmartGen API Caching System

The app includes a sophisticated caching system for the SmartGen API that provides:

### 🚀 **Performance Benefits**
- **5-minute cache duration** - Reduces API calls and improves response times
- **Offline capability** - Uses cached data when SmartGen API is unavailable
- **Automatic background sync** - Syncs fresh data to Airtable in the background

### 🔄 **How SmartGen Caching Works**
1. **First Request**: Fetches data from SmartGen API and caches it
2. **Subsequent Requests**: Uses cached data (within 5 minutes)
3. **Cache Expiry**: Automatically fetches fresh data after 5 minutes
4. **Background Sync**: Fresh data is automatically synced to Airtable
5. **Fallback**: If SmartGen fails, falls back to backend server

### 📊 **SmartGen API Details**
- **Endpoint**: `https://www.smartgencloudplus.com/yewu/third/genset/list`
- **Authentication**: Uses `utoken=bebf6914640ec3ed6bf00398fb7969da`
- **Parameters**: `page=1&per_page=10`
- **Cache Key**: `smartgen_genset_cache`
- **Cache Duration**: 5 minutes

### 💾 **Cache Management**
```dart
// Force refresh SmartGen data (bypass cache)
await BackendService.fetchGensets(forceRefresh: true);

// Clear all cached data
await BackendService.clearCache();

// Check if cache is valid
bool isValid = await BackendService._isCacheValid();
```

### 🔄 **Data Flow Architecture**
```
SmartGen API → Cache → UI Display
                    ↓
               Airtable Sync (Background)
```

### 📱 **Console Output Examples**
```
🎯 Attempting to fetch gensets from SmartGen API with caching...
⚡ Using cached SmartGen data
📦 Loaded 8 gensets from cache
🔄 Syncing 8 gensets to Airtable in background...
✅ Successfully synced 8/8 gensets to Airtable
```

### 🎯 **Cache Benefits**
- **Reduced API calls** - Only fetches when cache expires
- **Faster UI** - Instant loading from cache
- **Offline support** - Works with cached data
- **Background sync** - Airtable stays updated automatically
- **Error resilience** - Falls back gracefully

## Quick Start

### For Local Development

1. **Start your local backend server** on `http://localhost:3002` or `http://192.168.50.241:3000`
2. **Run the app in debug mode** - it will automatically use local configuration
3. **Check console logs** for configuration details

### Automatic Fallback (Recommended)

If Netlify is unavailable, the app will automatically switch to your local server:

```dart
import 'lib/config/config_manager.dart';

// Setup with automatic fallback to local server
ConfigManager.setupWithLocalFallback();
```

### Manual Environment Switching

```dart
import 'lib/config/config_manager.dart';

// Switch to local environment
ConfigManager.switchToLocal();

// Switch to staging
ConfigManager.switchToStaging();

// Switch to production
ConfigManager.switchToProduction();
```

### Fallback Control

```dart
// Force local fallback (useful when Netlify is down)
ConfigManager.forceLocalFallback();

// Reset and try Netlify again
ConfigManager.resetNetlifyStatus();

// Test Netlify connectivity
bool isReachable = await ConfigManager.testNetlifyConnection();
```

## Environment Configuration

### Local Environment (`config_local.dart`)
- **Backend URL**: `http://localhost:3002/`
- **Debug Mode**: Enabled
- **Mock Data**: Disabled
- **Best for**: Development and testing

### Staging Environment (`config_staging.dart`)
- **Backend URL**: `https://backendmirror-staging.netlify.app/.netlify/functions` (with fallback to `http://192.168.50.241:3000/`)
- **Debug Mode**: Enabled
- **Auto Fallback**: Enabled
- **Best for**: Pre-production testing

### Production Environment (`config_production.dart`)
- **Backend URL**: `https://backendmirror.netlify.app/.netlify/functions` (with fallback to `http://192.168.50.241:3000/`)
- **Debug Mode**: Disabled
- **Auto Fallback**: Enabled
- **Best for**: Live production app

## Automatic Fallback System

The app includes a smart fallback system that automatically switches to your local server if Netlify is unavailable:

### How It Works
1. **First Request**: App tries to connect to Netlify
2. **Connectivity Test**: If Netlify fails, automatically switches to local server
3. **Persistent Fallback**: Once failed, all subsequent requests use local server
4. **Manual Reset**: You can reset the status to try Netlify again

### Fallback URLs
- **Primary**: Netlify functions (`https://backendmirror.netlify.app/.netlify/functions`)
- **Fallback**: Your local server (`http://192.168.50.241:3000/`)

### Console Output Examples
```
🔍 Testing backend connectivity...
❌ Netlify returned status 500
⚠️ Netlify is not reachable, switching to local server fallback
🏠 Local server should be running on: http://192.168.50.241:3000/
🌐 Using backend URL: http://192.168.50.241:3000/
🔄 Using local fallback server (Netlify unavailable)
```

### Setup Your Local Server
1. Navigate to your local backend directory: `C:\Users\tm\Documents\AI\Local Api Backend`
2. Install dependencies: `npm install`
3. Start server: `npm start` (should run on port 3000)
4. **Important**: Server must be accessible at `http://192.168.50.241:3000/`
5. The app will automatically detect and use it when Netlify fails

### Mobile Device Testing
- Your computer's IP: `192.168.50.241`
- Backend URL for mobile: `http://192.168.50.241:3000/`
- Make sure your phone and computer are on the same Wi-Fi network
- Test connection: Open browser on phone → `http://192.168.50.241:3000/`

## API Configuration (`api_config.dart`)

The main configuration file that manages environment switching:

```dart
// Check current environment
if (ApiConfig.isLocal) {
  // Local-specific code
}

if (ApiConfig.isStaging) {
  // Staging-specific code
}

if (ApiConfig.isProduction) {
  // Production-specific code
}

// Get URLs
String baseUrl = ApiConfig.baseUrl;
String backendUrl = ApiConfig.backendUrl;
```

## Setting Up Local Backend

### Prerequisites
- Node.js installed
- npm or yarn package manager

### Steps
1. Clone the backend repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Start the development server:
   ```bash
   npm start
   ```
4. Verify server is running on `http://localhost:3002`

### Mobile Testing
For testing on physical devices:
1. Find your computer's IP address
2. Update the local config to use your IP instead of `localhost`
3. Example: `http://192.168.1.100:3002/`
4. Make sure your device and computer are on the same network

## Configuration Files Structure

```
lib/
├── config/
│   ├── config_manager.dart    # Main configuration manager
│   ├── config_local.dart      # Local environment config
│   ├── config_staging.dart    # Staging environment config
│   └── config_production.dart # Production environment config
├── services/
│   └── api_config.dart        # API configuration with environment switching
└── main.dart                  # App initialization with config setup
```

## Usage Examples

### In Services
```dart
import '../services/api_config.dart';

class MyService {
  Future<void> fetchData() async {
    final url = '${ApiConfig.baseUrl}/endpoint';
    // Make API call
  }
}
```

### Environment-Specific Logic
```dart
import '../services/api_config.dart';

class DataService {
  bool shouldUseMockData() {
    return ApiConfig.isLocal && kDebugMode;
  }

  String getApiEndpoint() {
    if (ApiConfig.isLocal) {
      return 'http://localhost:3002/api/data';
    }
    return '${ApiConfig.backendUrl}/data';
  }
}
```

### Debugging Configuration
```dart
import '../config/config_manager.dart';

// Print current configuration
ConfigManager.printCurrentConfig();

// Get configuration as map
final config = ConfigManager.getCurrentConfig();
print('Environment: ${config['environment']}');
```

## Build Configuration

### Debug Builds (Development)
- Automatically uses **Local** environment
- Full debugging enabled
- Console logs visible

### Profile/Release Builds (Production)
- Automatically uses **Production** environment
- Debugging disabled
- Optimized for performance

### Manual Environment Override
```dart
// In main.dart or anywhere before app initialization
ConfigManager.initialize(environment: Environment.staging);
```

## Troubleshooting

### Common Issues

1. **"Connection refused" error**
   - Check if local backend server is running
   - Verify the port (default: 3002)
   - For mobile devices, use IP address instead of localhost

2. **Wrong environment selected**
   - Check console logs for current configuration
   - Use `ConfigManager.printCurrentConfig()` to verify
   - Manually switch environments if needed

3. **API calls failing**
   - Verify backend URLs in config files
   - Check network connectivity
   - Ensure backend server is accessible

### Debug Commands
```dart
// Print current configuration
ConfigManager.printCurrentConfig();

// Switch environments
ConfigManager.switchToLocal();
ConfigManager.switchToStaging();
ConfigManager.switchToProduction();

// Check API config
ApiConfig.printConfig();
```

## Best Practices

1. **Never hardcode URLs** - Always use `ApiConfig.baseUrl` or `ApiConfig.backendUrl`
2. **Test all environments** before releasing
3. **Use environment-specific logic** when needed (e.g., mock data for local)
4. **Keep sensitive data** in environment variables (.env file)
5. **Document API changes** in this README

## Environment Variables

The app also uses `.env` file for sensitive configuration:

```env
AIRTABLE_API_KEY=your_airtable_key
AIRTABLE_BASE_ID=your_base_id
AIRTABLE_TABLE_NAME=your_table
SMARTGEN_UTOKEN=your_token
```

## Contributing

When adding new features:
1. Update configuration files if new environment-specific settings are needed
2. Test on all environments (Local, Staging, Production)
3. Update this documentation if new configuration options are added
4. Use the configuration system instead of hardcoding values

## Support

For configuration issues:
1. Check console logs for configuration details
2. Verify backend servers are running
3. Test network connectivity
4. Review environment-specific settings

---

**Last Updated**: November 2025
**Version**: 1.0.0

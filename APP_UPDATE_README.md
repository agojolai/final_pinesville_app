# App Update System - Implementation Guide

## Overview
The Pinesville app includes an automatic update notification system that alerts users when new versions are available via GitHub releases. The app downloads APK files in-app and automatically prompts installation.

## How It Works

### Architecture
- **Single APK**: One app binary for all users
- **Single Appcast**: One XML file controls update notifications for everyone
- **Automatic Check**: App checks for updates on startup
- **In-App Download**: APK downloads in background with progress notification
- **Auto-Install Prompt**: System install dialog opens after download completes

### User Experience
1. User opens the app
2. App checks appcast.xml for new version
3. If new version available → Shows update dialog
4. User taps "UPDATE NOW" → APK download starts
5. Download progress shown in notification bar
6. Download completes → System install prompt appears
7. User taps "Install" → App updates

## File Structure

\\\
application_pinesville/
 appcast.xml                                    # Update feed (commit to repo)
 lib/src/features/app_update/
     data/
         app_update_service.dart               # Update check logic
         apk_download_service.dart             # APK download & install
 android/app/src/main/
     AndroidManifest.xml                       # Permissions & FileProvider
     res/xml/
         provider_paths.xml                    # File access paths
\\\

## Releasing Updates

### Step 1: Update Version in pubspec.yaml
\\\yaml
version: 1.1.0+3  # Increment version number
\\\

### Step 2: Update appcast.xml
\\\xml
<item>
    <title>Version 1.1.0</title>
    <description>
 New feature 1
 New feature 2
 Bug fixes
    </description>
    <pubDate>Thu, 28 Nov 2025 10:00:00 +0000</pubDate>
    <enclosure 
        url="https://github.com/agojolai/final_pinesville_app/releases/download/v1.1.0/pinesville-v1.1.0.apk" 
        sparkle:version="1.1.0" 
        sparkle:os="android" />
</item>
\\\

**IMPORTANT**: The `url` field must be a **direct download link** to the APK file:
- ✅ Correct: `https://github.com/{user}/{repo}/releases/download/v1.1.0/app.apk`
- ❌ Wrong: `https://github.com/{user}/{repo}/releases/tag/v1.1.0`

### Step 3: Build and Release
\\\ash
# Build release APK
flutter build apk --release

# Commit appcast changes
git add appcast.xml pubspec.yaml
git commit -m "chore: Release v1.1.0"
git push origin main

# Create GitHub release
# - Go to: https://github.com/agojolai/final_pinesville_app/releases/new
# - Create tag: v1.1.0
# - Upload: build/app/outputs/flutter-apk/app-release.apk
# - Rename uploaded file to match URL in appcast (e.g., pinesville-v1.1.0.apk)
# - Add release notes from appcast description
# - Publish release
\\\

### Result
All users (admin and tenant) will:
1. See update notification on next app launch
2. Tap "UPDATE NOW" to download APK in-app
3. Get system install prompt after download completes

## Prerequisites for In-App Download

### User Requirements
Users must enable "Install from Unknown Sources" for the app:
1. Android will prompt for this permission on first install attempt
2. Or manually: **Settings → Apps → Special app access → Install unknown apps → Pinesville → Allow**

### System Requirements
- **Android 8.0+** (API level 26+) - For REQUEST_INSTALL_PACKAGES permission
- **Internet connection** - Required for download
- **Storage space** - ~50MB minimum for APK download

## Appcast XML Format

\\\xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>Pinesville App - Updates</title>
        <description>Update feed for all Pinesville users</description>
        <language>en</language>
        <item>
            <title>Version X.Y.Z</title>
            <description>
 Feature 1
 Feature 2
 Bug fixes
            </description>
            <pubDate>Day, DD Mon YYYY HH:MM:SS +0000</pubDate>
            <enclosure 
                url="https://github.com/agojolai/final_pinesville_app/releases/tag/vX.Y.Z" 
                sparkle:version="X.Y.Z" 
                sparkle:os="android" />
        </item>
    </channel>
</rss>
\\\

## GitHub Setup

### 1. Commit Appcast File
\\\ash
git add appcast.xml
git commit -m "feat: Add app update notification system"
git push origin main
\\\

### 2. Verify Appcast URL
Check that this URL is accessible:
\https://raw.githubusercontent.com/agojolai/final_pinesville_app/main/appcast.xml\

## Configuration

### Current Settings
- **Check frequency**: Every 3 days after dismissing
- **Debug logging**: Disabled (set to \	rue\ in \pp_update_service.dart\ for testing)
- **Dialog style**: Material (Android default)
- **Appcast URL**: Single feed for all users

### Customization Options

**Change alert frequency** (in \pp_update_service.dart\):
\\\dart
durationUntilAlertAgain: const Duration(days: 7), // Weekly
\\\

**Enable debug logging**:
\\\dart
debugLogging: true, // See update check logs
\\\

**Force update** (in \pp.dart\):
\\\dart
UpgradeAlert(
  upgrader: upgrader,
  showIgnore: false,  // Hide ignore button
  showLater: false,   // Hide later button
  child: ...,
)
\\\

**Always show dialog for testing**:
\\\dart
final upgrader = Upgrader(
  debugDisplayAlways: true,  // Always show dialog
  // ... other config
);
\\\

## Testing

### Test with Debug Mode
1. In \pp_update_service.dart\, set:
\\\dart
debugLogging: true,
\\\

2. In \pp.dart\, temporarily add:
\\\dart
final upgrader = Upgrader(
  debugDisplayAlways: true,
  storeController: UpgraderStoreController(
    onAndroid: () => UpgraderAppcastStore(
      appcastURL: 'https://raw.githubusercontent.com/agojolai/final_pinesville_app/main/appcast.xml',
      osVersion: Version(1, 0, 0),
    ),
  ),
);
\\\

3. Run app and check console logs

### Test Update Flow
1. Set appcast version higher than current (e.g., 999.0.0)
2. Set appcast URL to a test APK download link
3. Open app
4. Verify dialog appears with correct message
5. Tap "UPDATE NOW"
6. Check notification bar for download progress
7. Wait for download to complete
8. Verify install prompt appears

## Troubleshooting

### Update Dialog Not Showing
- Check appcast version > current app version (\pubspec.yaml\)
- Verify appcast URL is accessible (open in browser)
- Enable \debugLogging: true\ to see logs
- Check if 3 days have passed since last dismissal
- Clear app data to reset dismissal state

### Download Not Starting
- Check logs for "Starting APK download from:" message
- Verify appcast URL contains **direct download link** (not release page)
- Test URL in browser - should download APK directly
- Check internet connection
- Verify storage permission granted

### Download Fails or Stalls
- Check available storage space (need ~50MB)
- Verify GitHub release URL is publicly accessible
- Check APK file size - large files may timeout on slow connections
- Look for error in logs: "Download failed"

### Install Prompt Not Appearing
- Check notification bar - tap notification to open install prompt
- Verify "Install from Unknown Sources" permission enabled
- Check logs for "Installing APK from:" message
- Ensure APK downloaded to correct path: `[external storage]/Downloads/pinesville_update.apk`

### "App Not Installed" Error
- APK might be corrupted - check download completed successfully
- Verify APK signed with same certificate as installed app
- Try clearing Downloads folder and downloading again

### Wrong Version Displayed
- Ensure \sparkle:version\ in appcast matches GitHub release tag
- Verify pubspec.yaml version format: \MAJOR.MINOR.PATCH+BUILD\

## Version Management

### Current Version
Check \pubspec.yaml\:
\\\yaml
version: 1.0.0+2
\\\

**Format**: \MAJOR.MINOR.PATCH+BUILD\
- **1.0.0**: User-facing version (shown in appcast)
- **+2**: Build number (internal, auto-increments)

### Updating Version
1. Update \pubspec.yaml\: \ersion: 1.1.0+3\
2. Update \ppcast.xml\ with new version and release notes
3. Build APK: \lutter build apk --release\
4. Create GitHub release with matching tag (\1.1.0\)
5. Upload APK to release

## Best Practices

1. **Test appcast XML** - Validate XML syntax before committing
2. **Match versions exactly** - Appcast version must match pubspec.yaml
3. **Use semantic versioning** - MAJOR.MINOR.PATCH format
4. **Clear release notes** - Help users understand what changed
5. **Test before release** - Verify update flow with debug mode
6. **Consistent tagging** - Use \X.Y.Z\ format for Git tags

## Example Release Workflow

\\\ash
# 1. Update version
# Edit pubspec.yaml: version: 1.1.0+3

# 2. Update appcast.xml with new version and notes

# 3. Build release
flutter clean
flutter pub get
flutter build apk --release

# 4. Test locally (optional)
flutter install

# 5. Commit changes
git add pubspec.yaml appcast.xml
git commit -m "chore: Release v1.1.0"
git push origin main

# 6. Create GitHub release
# - Tag: v1.1.0
# - Upload: build/app/outputs/flutter-apk/app-release.apk
# - Copy release notes from appcast.xml
# - Publish

# 7. Verify appcast URL shows new version
# Visit: https://raw.githubusercontent.com/agojolai/final_pinesville_app/main/appcast.xml
\\\

## Notes

- **In-App Download**: APK downloads in background with progress notification
- **Auto-Install Prompt**: System install dialog opens automatically after download
- **Permission Required**: Users must enable "Install from Unknown Sources" once
- **Internet Required**: App checks appcast and downloads APK over network
- **Platform Support**: Currently configured for Android only
- **Update Frequency**: Checks on every app launch (respects 3-day delay after dismissal)
- **Background Download**: Uses Android WorkManager - persists across app restarts
- **Download Location**: `[External Storage]/Downloads/pinesville_update.apk`

## Technical Details

### Packages Used
- **upgrader (^12.3.0)**: Update notification dialog and appcast parsing
- **flutter_downloader (^1.11.10)**: Background APK download with notifications
- **open_filex (^4.5.0)**: Opens APK to trigger system install prompt
- **permission_handler (^11.3.1)**: Manages storage permissions
- **xml (^6.5.0)**: Parses appcast RSS feed to extract APK URL
- **http**: Fetches appcast.xml from GitHub

### Android Permissions
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```

### FileProvider Configuration
- **Provider**: `vn.viettuts.fileprovider`
- **Paths**: External storage, cache, internal files
- **Purpose**: Secure file access for APK installation

### Download Flow
1. User taps "UPDATE NOW" → `onUpdate()` callback
2. `App._handleUpdate()` → Retrieves APK URL from appcast
3. `AppUpdateService.getApkDownloadUrl()` → HTTP fetch + XML parse
4. `ApkDownloadService.downloadAndInstall()` → Requests permissions
5. `FlutterDownloader.enqueue()` → Starts background download
6. Android notification shows progress
7. Download completes → Callback triggered
8. `OpenFilex.open()` → System install prompt

### Error Handling
- Storage permission denial → Logs error, returns false
- Download failure → Logs error in callback
- Install failure → Logs OpenFilex result message
- All errors logged via AppLogger for debugging

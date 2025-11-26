# Pinesville Mobile Application 🏠

> **Version 1.0.5** | Property Management System for Android

A comprehensive Flutter-based mobile application for residential property management, designed to provide seamless communication and services between tenants and building administrators.

## 📋 Table of Contents
- [Features](#-features)
- [Tech Stack](#-technical-architecture)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#-installation--setup)
- [Firebase Configuration](#-firebase-configuration)
- [Building for Production](#-building-for-production)
- [Deployment](#-deployment)
- [Environment Variables](#-environment-variables)
- [Security Checklist](#-security-checklist)
- [Troubleshooting](#-troubleshooting)
- [License & Dependencies](#-license--dependencies)

## 🌟 Features

### 🏠 **Home Dashboard**
- Real-time billing overview with current balance
- Recent transaction history
- Important announcements and notifications
- Quick access to essential services

### 💳 **Payment Management**
- Multiple payment methods (GCash, BDO, Cash)
- QR code payments with secure transaction processing
- Upload proof of payment with image capture
- View detailed billing statements with utility breakdown
- Transaction history tracking

### 👤 **Profile & Account Management**
- Real-time user profile with Riverpod state management
- Multiple occupant management with CRUD operations
- Secure account settings and password management
- Profile picture upload and management
- Contract and property information

### 🎯 **Support & Communication**
- Submit maintenance requests and reports
- Track report status with real-time updates
- Category-based issue reporting (Maintenance, Billing, Complaints)
- Direct admin communication system
- Attachment support for reports

### 🚀 **Onboarding Experience**
- Interactive 5-page walkthrough for new users
- Skip functionality and progress tracking
- Smooth animations and haptic feedback
- Local storage persistence
- Developer testing tools

### 🔐 **Authentication & Security**
- Firebase Authentication integration
- Secure user registration and login
- Password reset functionality
- Session management with automatic logout
- **Role-based access control (Admin/Tenant)**

### 🔧 **Admin Management System**
- **Admin Dashboard**: Visual property overview, stats, and quick actions
- **Tenant Management**: Search, filter, and manage all tenant records
- **Billing Management**: Track payment statuses and generate billing statements
- **Reports & Analytics**: Financial and occupancy insights with filtering
- **Announcements**: Create and manage property-wide communications
- **Role-based Navigation**: Separate admin and tenant interfaces

## 🛠 Technical Architecture

### **Frontend Framework**
- **Flutter** (SDK ^3.5.4) - Cross-platform mobile development
- **Material Design 3** - Modern UI components and theming
- **Responsive Design** - Optimized for various screen sizes

### **State Management**
- **Riverpod** (^2.5.1) - Reactive state management
- **StreamProvider & FutureProvider** - Real-time data handling
- **StateNotifier** - Complex state management patterns

### **Backend Services**
- **Firebase Core** (^4.0.0) - Backend as a Service
- **Firebase Auth** (^6.0.0) - User authentication
- **Cloud Firestore** (^6.0.0) - NoSQL database
- **Firebase Storage** (^13.0.0) - File storage and management
- **Firebase App Check** (^0.4.0) - Security and abuse prevention

### **Key Dependencies**
```yaml
# UI & Icons
iconsax: ^0.0.8                    # Consistent icon set
cupertino_icons: ^1.0.8           # iOS-style icons

# Storage & Persistence
get_storage: ^2.1.1               # Local data persistence
image_picker: ^1.1.2              # Camera and gallery access
image_cropper: ^9.1.0             # Image editing capabilities

# Network & Connectivity
http: ^1.3.0                      # HTTP client
connectivity_plus: ^6.1.2         # Network connectivity detection

# UI Enhancements
smooth_page_indicator: ^1.2.0+3   # Page indicators
flutter_native_splash: ^2.4.4     # Custom splash screens
```

## 📁 Project Structure

```
lib/
├── src/
│   ├── core/                     # Core business logic
│   │   ├── repositories/         # Data layer abstractions
│   │   ├── exceptions/           # Custom exception handling
│   │   └── constants/            # App-wide constants
│   ├── features/                 # Feature-based modules
│   │   ├── auth/                 # Authentication & user management
│   │   ├── home/                 # Dashboard and home screen
│   │   ├── payment/              # Billing and payment processing
│   │   ├── profile/              # User profile management
│   │   ├── support/              # Reports and support tickets
│   │   └── onboarding/           # User onboarding flow
│   ├── theme/                    # UI theming and styling
│   └── common/                   # Shared widgets and utilities
├── app.dart                      # Main app configuration
└── main.dart                     # App entry point
```

## 📦 Prerequisites

Before deployment, ensure you have:

### Development Environment
- **Flutter SDK**: ^3.5.4 ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: Included with Flutter
- **Android Studio** or **VS Code** with Flutter/Dart extensions
- **JDK**: OpenJDK 21+ (for Android builds)
- **Git**: Version control

### Required Accounts
- **Firebase Project**: [Create Firebase Project](https://console.firebase.google.com/)
- **Google Play Console**: (for Play Store deployment)
- **Code Signing**: Android keystore (for release builds)

### System Requirements
- **OS**: Windows 10+, macOS, or Linux
- **RAM**: 8GB minimum (16GB recommended)
- **Storage**: 10GB free space

---

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/agojolai/final_pinesville_app.git
cd application_pinesville
```

### 2. Install Dependencies
```bash
# Get Flutter packages
flutter pub get

# Verify Flutter installation
flutter doctor -v
```

### 3. Configure Firebase (Critical)

#### Download Firebase Config Files
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project → Project Settings
3. Download configuration files:
   - **Android**: `google-services.json` → `android/app/`
   - **iOS**: `GoogleService-Info.plist` → `ios/Runner/`

#### Enable Firebase Services
```bash
# In Firebase Console, enable:
- Authentication (Email/Password)
- Cloud Firestore
- Firebase Storage
- App Check (recommended for production)
- Cloud Messaging (for push notifications)
```

#### Set Firestore Security Rules
```javascript
// Deploy these rules to Firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can only read/write their own data
    match /Users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Admin collection - restricted access
    match /admin/{document=**} {
      allow read, write: if false; // Access via server-side only
    }
    
    // Bills - users can read their own bills
    match /Bills/{billId} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow write: if false; // Admin creates bills via Functions
    }
    
    // Payments - users can create/read their payments
    match /Payments/{paymentId} {
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow update, delete: if false;
    }
  }
}
```

### 4. Run in Development Mode
```bash
# Connect Android device/emulator
flutter devices

# Run debug build
flutter run --debug

# Hot reload is enabled (press 'r' in terminal)
```

---

## 🔧 Building for Production

### Generate Android Keystore (First Time Only)
```bash
# Navigate to android/app
cd android/app

# Generate keystore
keytool -genkey -v -keystore pinesville-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias pinesville-key

# Enter strong passwords and details when prompted
# IMPORTANT: Store passwords securely (do NOT commit keystore)
```

### Configure Signing (android/app/build.gradle.kts)
```kotlin
// Add above android block
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### Create key.properties (android/key.properties)
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=pinesville-key
storeFile=app/pinesville-release-key.jks
```

⚠️ **Add to .gitignore** (already configured):
```gitignore
android/key.properties
android/app/*.jks
```

### Build Release APK
```bash
# Clean previous builds
flutter clean
flutter pub get

# Build release APK (for testing/sideload)
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (for Play Store)
```bash
# Build optimized AAB (recommended for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## 🚀 Deployment

### Google Play Store Deployment

#### 1. Prepare App Listing
- App name: **Pinesville**
- Package name: `com.pinesville.app` (set in `android/app/build.gradle.kts`)
- Icon: 512x512px (generated via `flutter_launcher_icons`)
- Screenshots: Minimum 2 (phone + tablet)
- Privacy policy URL
- Content rating questionnaire

#### 2. Upload to Play Console
```bash
# 1. Login to Google Play Console
# 2. Create new app or select existing
# 3. Production → Create new release
# 4. Upload app-release.aab
# 5. Fill release notes
# 6. Review and rollout
```

#### 3. Internal Testing Track (Recommended First)
```bash
# Test with closed group before production:
1. Create Internal Testing release
2. Add tester emails
3. Share opt-in link
4. Gather feedback
5. Fix issues
6. Promote to Production
```

### Firebase Hosting (for Web - Optional)
```bash
# Build Flutter web
flutter build web --release

# Install Firebase CLI
npm install -g firebase-tools

# Login and init
firebase login
firebase init hosting

# Deploy
firebase deploy --only hosting
```

### Over-the-Air Updates (via Firebase)
```bash
# Enable Remote Config for feature flags
# Use Cloud Functions to notify users of updates
# Implement in-app update prompts with upgrader package
```

---

## 🔐 Environment Variables

### Firebase Configuration (Auto-generated)
- **File**: `lib/firebase_options.dart`
- **Generated by**: `flutterfire configure`
- **Contains**: API keys, project IDs, app IDs
- **Safe to commit**: Yes (client-side keys, secured by Firestore rules)

### Secrets to NEVER Commit
❌ `android/key.properties` - Keystore passwords
❌ `android/app/*.jks` - Signing keys
❌ `functions/serviceAccount*.json` - Firebase admin credentials
❌ `.env` files with sensitive data

✅ Already protected by `.gitignore`

### Recommended Secret Management
```bash
# For CI/CD, use encrypted secrets:
- GitHub Secrets (for GitHub Actions)
- Bitbucket Pipelines variables
- GitLab CI/CD variables

# For local development:
- Use key.properties (ignored by git)
- Store keystore outside repo
```

---

## 🛡️ Security Checklist

Before deploying to production:

### Firebase Security
- [ ] Firestore rules deployed (test in Firestore Rules Playground)
- [ ] Firebase Storage rules configured (user-specific paths)
- [ ] App Check enabled and enforced
- [ ] Authentication domains whitelisted (Firebase Console → Auth → Settings)
- [ ] API key restrictions (Google Cloud Console → APIs & Services → Credentials)

### App Security
- [ ] ProGuard/R8 enabled for code obfuscation (`android/app/build.gradle.kts`)
- [ ] Remove all debug logs (`print()`, `debugPrint()`)
- [ ] Disable Flutter Inspector in release mode (automatic)
- [ ] Validate all user inputs
- [ ] HTTPS only for API calls

### Build Security
- [ ] Release build signed with production keystore
- [ ] Keystore backed up in secure location (NOT in repo)
- [ ] `key.properties` in `.gitignore`
- [ ] No hardcoded credentials in source code

### Data Privacy
- [ ] Privacy policy published and linked
- [ ] GDPR compliance (data export/deletion)
- [ ] User consent for data collection
- [ ] Secure password storage (Firebase Auth handles this)

---

## 🐛 Troubleshooting

### Common Build Issues

#### "google-services.json not found"
```bash
# Solution: Download from Firebase Console
# Place in: android/app/google-services.json
```

#### "Keystore not found" or Signing Errors
```bash
# Check paths in key.properties
# Ensure storeFile path is correct relative to android/
# Example: storeFile=app/pinesville-release-key.jks
```

#### "Build failed: Execution failed for task ':app:processReleaseGoogleServices'"
```bash
# Firebase config mismatch
flutter clean
flutter pub get
# Re-download google-services.json
# Ensure package name matches in build.gradle.kts and Firebase Console
```

#### "Firestore permission denied"
```bash
# Check Firestore rules in Firebase Console
# Ensure user is authenticated
# Verify userId matches in rules
```

### Performance Issues
```bash
# Build with --release flag (not --debug)
flutter build apk --release --split-per-abi

# Analyze app size
flutter build apk --analyze-size

# Profile performance
flutter run --profile
```

### Debugging Production Issues
```bash
# Check Flutter logs
flutter logs

# Firebase Crashlytics (recommended to add)
firebase crashlytics:test

# Monitor in Play Console
# → Vitals → Crashes & ANRs
```

---

## 🔥 Firebase Configuration

### Firestore Database Structure
```
Users/{userId}/
├── profile/
│   ├── firstName: string
│   ├── lastName: string
│   ├── email: string
│   ├── phoneNumber: string
│   └── profilePicture: string
├── property/
│   ├── propertyName: string
│   ├── unitId: string
│   └── moveInDate: timestamp
├── account/
│   ├── status: string
│   └── createdAt: timestamp
└── occupants/{occupantId}/
    ├── occupantName: string
    └── occupantPhone: string
```

### Authentication Setup
- Email/Password authentication
- Password reset functionality
- User profile creation and management

## 🎨 UI/UX Design

### Design System
- **Typography**: Montserrat and Poppins font families
- **Color Scheme**: Material Design 3 dynamic colors
- **Animations**: Smooth transitions with custom curves
- **Accessibility**: WCAG compliant with proper contrast ratios

### Responsive Design
- Optimized for Android devices
- Adaptive layouts for different screen sizes (mobile, tablet, desktop)
- Touch-friendly interactive elements
- **Navigation System:**
  - Side navigation rail for tablets in landscape mode
  - Bottom navigation for mobile and portrait tablets
  - Adaptive icons and labels with proper scaling
- **Tablet Mode Optimizations:**
  - Admin dashboard with responsive grid layouts
  - Multi-column tenant management view  
  - Adaptive content width and spacing
  - Responsive navigation and component scaling
  - Two-panel layouts for better space utilization
  - **Font Scaling Fixes:** Prevents oversized text on tablets

## 🧪 Testing

Run tests with:
```bash
flutter test
```

### Test Coverage
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user flows

## 📱 Supported Platforms

- **Android** (API level 21+)

## 🔧 Development Tools

- **Flutter Inspector** - UI debugging
- **Firebase Console** - Backend management  
- **VSCode Extensions** - Flutter, Dart, Firebase
- **Linting** - flutter_lints for code quality

## 📄 Documentation

### 📚 Complete Documentation
All documentation has been organized into a structured folder system. See **[Documentation Index](docs/README.md)** for complete navigation.

### 🚀 Quick Access
- **[Billing System](docs/features/billing/README.md)** - Complete billing implementation guide
- **[Consumption Analytics](docs/features/consumption-analytics/README.md)** - Usage tracking and analysis
- **[Database Structure](docs/database/billing-structure.md)** - Firestore schema reference
- **[Quick References](docs/quick-references/README.md)** - Code snippets for rapid development
- **[Implementation Checklist](docs/guides/implementation-checklist.md)** - Project status and roadmap

### 📖 By Feature
- [Billing Documentation](docs/features/billing/) - Payment processing and bill management
- [Consumption Analytics](docs/features/consumption-analytics/) - Utility usage tracking
- [User Profile](docs/features/user-profile/) - Profile management
- [Onboarding](docs/features/onboarding/) - First-time user experience
- [Reports](docs/features/reports/) - Reporting and analytics

### 📋 Project Status
- [Phase 1 Completion](docs/project-phases/phase-1-completion.md) - Foundation features ✅
- [Phase 2 Completion](docs/project-phases/phase-2-completion.md) - Billing system ✅
- [Implementation Checklist](docs/guides/implementation-checklist.md) - Current status and roadmap

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License & Dependencies

### Application License
**Proprietary Software**

Copyright © 2025 Pinesville Management. All rights reserved.

This software and associated documentation files (the "Software") are the proprietary property of Pinesville Management. Unauthorized copying, modification, distribution, or use of this software, via any medium, is strictly prohibited without explicit written permission from Pinesville Management.

**Restrictions:**
- No commercial use without license
- No redistribution or resale
- No reverse engineering
- Source code is confidential

**Permitted Use:**
- Internal use by Pinesville Management and authorized tenants
- Deployment to authorized app stores under Pinesville brand

For licensing inquiries: legal@pinesville.com

---

### Third-Party Dependencies

This application uses the following open-source packages:

#### Core Framework
- **Flutter** (BSD 3-Clause License) - © Google LLC
- **Dart** (BSD 3-Clause License) - © Dart Team

#### Firebase Services (Apache 2.0 License)
- `firebase_core` ^4.0.0
- `firebase_auth` ^6.0.0
- `cloud_firestore` ^6.0.0
- `firebase_storage` ^13.0.0
- `firebase_app_check` ^0.4.0
- `firebase_messaging` ^16.0.2

#### State Management (MIT License)
- `flutter_riverpod` ^2.5.1 - © Remi Rousselet
- `get_storage` ^2.1.1
- `get` ^4.6.6

#### UI/UX Libraries
- `iconsax` ^0.0.8 (MIT) - Icon set
- `smooth_page_indicator` ^1.2.0+3 (MIT)
- `flutter_screenutil` ^5.5.0 (Apache 2.0)
- `flutter_native_splash` ^2.4.4 (MIT)

#### Media & Files
- `image_picker` ^1.1.2 (Apache 2.0)
- `image_cropper` ^11.0.0 (BSD 3-Clause)
- `file_picker` ^8.1.6 (MIT)
- `gal` ^2.3.0 (MIT)
- `path_provider` ^2.1.5 (BSD 3-Clause)

#### Utilities
- `http` ^1.3.0 (BSD 3-Clause)
- `connectivity_plus` ^7.0.0 (BSD 3-Clause)
- `url_launcher` ^6.3.1 (BSD 3-Clause)
- `intl` ^0.20.1 (BSD 3-Clause)
- `logger` ^2.5.0 (MIT)
- `csv` ^6.0.0 (Apache 2.0)
- `dio` ^5.9.0 (MIT)

#### Additional Tools
- `upgrader` ^12.3.0 (BSD 3-Clause) - In-app update prompts
- `flutter_to_pdf` ^0.4.0 (MIT) - PDF generation
- `screenshot` ^3.0.0 (MIT)
- `video_player` ^2.10.0 (BSD 3-Clause)
- `package_info_plus` ^8.1.2 (BSD 3-Clause)

Full dependency licenses available in each package's `LICENSE` file.

**Compliance Notes:**
- All dependencies are compatible with proprietary app distribution
- No GPL/AGPL dependencies (copyleft avoided)
- Attribution requirements met via in-app "About" screen

---

## 📞 Support & Contact

### For Deployment Issues
- **Technical Lead**: Pinesville Development Team
- **Email**: dev@pinesville.com
- **GitHub Issues**: [Report a bug](https://github.com/agojolai/final_pinesville_app/issues)

### For End Users (Tenants/Admins)
- **In-app Support**: Use Support tab → Submit Report
- **Email**: support@pinesville.com
- **Phone**: +63 XXX XXXX (Business hours)

### Production Monitoring
- **Firebase Console**: [View Analytics](https://console.firebase.google.com/)
- **Google Play Console**: [View Vitals](https://play.google.com/console/)
- **Status Page**: status.pinesville.com (if available)

---

## 📊 Version History

### v1.0.5 (Current - November 2025)
- ✅ Full billing system with partial payments
- ✅ Admin dashboard and tenant management
- ✅ Terms & Conditions dialog on registration
- ✅ Role-based navigation (Admin/Tenant)
- ✅ Payment proof upload with image cropper
- ✅ Late fee calculation with freezing logic
- ✅ Consumption analytics foundation
- ✅ Tablet responsive design

### Upcoming Features
- [ ] Push notifications for bills and announcements
- [ ] In-app chat between admin and tenants
- [ ] Consumption analytics charts
- [ ] Automated late fee reminders
- [ ] Multi-language support (English/Filipino)

---

## 🔗 Related Documentation

- **[Documentation Index](docs/README.md)** - Complete technical docs
- **[Billing System Guide](docs/features/billing/README.md)** - Payment workflows
- **[Database Schema](docs/database/billing-structure.md)** - Firestore structure
- **[Security Best Practices](docs/guides/security.md)** - (If exists)
- **[API Reference](docs/api/)** - Cloud Functions docs

---

## 🙏 Acknowledgments

Built with:
- [Flutter](https://flutter.dev/) - Google's UI toolkit
- [Firebase](https://firebase.google.com/) - Google Cloud backend
- [Riverpod](https://riverpod.dev/) - Remi Rousselet's state management
- [Iconsax](https://iconsax.io/) - Modern icon library

Special thanks to the Flutter and Firebase communities.

---

**© 2025 Pinesville Management. All rights reserved.**

*Last Updated: November 26, 2025*  
*README Version: 2.0 (Deployment-Ready)*

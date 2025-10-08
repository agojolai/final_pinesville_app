# Pinesville Mobile Application 🏠

A comprehensive Flutter-based mobile application for residential property management, designed to provide seamless communication and services between tenants and building administrators.

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

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.5.4)
- Dart SDK
- Firebase project setup
- IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd application_pinesville
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Set up a Firebase project
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Configure Firestore security rules
   - Enable Authentication providers

4. **Run the application**
   ```bash
   flutter run
   ```

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

## 📝 License

This project is proprietary software owned by Pinesville Management.

## 📞 Support

For technical support and inquiries, contact:
- **Developer**: Pinesville Development Team
- **Version**: 1.0.0
- **Last Updated**: September 2025

---

**© 2025 Pinesville. All rights reserved.**

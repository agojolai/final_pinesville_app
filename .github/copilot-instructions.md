# Pinesville Mobile App - AI Coding Agent Instructions

## Project Overview
This is a **Flutter property management application** for residential buildings, handling tenant-admin communication, billing with partial payments, and multi-role access control. Built with **Firebase backend** and **Riverpod** state management.

## Critical Architecture Patterns

### 1. **Feature-Based Architecture**
```
lib/src/features/{feature}/
  ├── data/          # Repository pattern for Firebase operations
  ├── domain/        # Models (BillModel, UserModel, PaymentModel)
  ├── presentation/  # Screens and UI widgets
  └── providers/     # Riverpod providers
```
**Key principle**: All Firebase queries go through repositories. Never access Firestore directly from UI code.

### 2. **Riverpod State Management**
- Use `StreamProvider.family` for real-time Firestore data (e.g., `userBillsProvider`)
- Use `FutureProvider.family` for one-time fetches (e.g., `billProvider`)
- Use `StateNotifierProvider` for complex state with mutations
- Access with `ref.watch()` in widgets, `ref.read()` in callbacks
- Example from `lib/src/features/billing/presentation/billing_providers.dart`:
  ```dart
  final userBillsProvider = StreamProvider.family<List<BillModel>, String>((ref, userId) {
    final repository = ref.watch(billingRepositoryProvider);
    return repository.getUserBills(userId);
  });
  ```

### 3. **Role-Based Access Control**
- `UserRole` enum: `tenant` or `admin` (see `lib/src/features/auth/data/models/user_model.dart`)
- Navigation splits via `RoleBasedNavigation` widget:
  - Admins → `AdminShell` (side/bottom nav with dashboard, tenant management, billing)
  - Tenants → `MainNavigation` (bottom nav with home, billing, profile, support)
- Always check user role when implementing features - never expose admin functions to tenant UI

### 4. **Firebase Structure**
Critical collections (see `BILLING_DATABASE_STRUCTURE.md`):
- `Users/{userId}/` - Nested structure with `profile`, `property`, `account` subcollections
- `Bills/{billId}/` - Contains `billingPeriod`, `utilities`, `paymentBreakdown`, `lateFeeDetails`
  - **Note**: `additionalCharges` array removed (Oct 2025) - data now only in `paymentBreakdown`
- `Payments/{paymentId}/` - Tracks partial payments with `allocations[]` array
- `Property/{propertyId}/` - Property-level utility rates and fixed charges
  - **Fixed charges location**: `Property/{propertyId}/fixedCharges/{trash, wifi, parking}` (NOT inside utilityRates)
- `Property/{propertyId}/Units/{unitId}` - Unit details with `lastReadings` for meter data
  - **Note**: Unit-level parking removed (Oct 2025) - now managed at property level

**Payment breakdown structure**: Every bill has 7 categories (rent, electricity, water, trash, wifi, parking, additionalCharges) with `amount`, `amountPaid`, `balance`, `isPaid`, `paidAt` tracked separately for partial payments. Additional charges category now includes optional `description` field for admin-provided context.

## Development Workflows

### Running the App
```powershell
flutter pub get              # Install dependencies
flutter run                  # Debug mode
flutter build apk --debug    # Build debug APK
```
Or use VS Code tasks: "Install Dependencies", "Flutter Run", "Build Debug APK"

### Testing
```dart
// Run tests with:
flutter test

// Example test structure (test/user_profile_test.dart):
void main() {
  group('UserModel', () {
    test('should create UserModel with proper nested structure', () {
      // Tests use actual models from lib/src/features/
    });
  });
}
```

### Firebase Initialization
**Critical**: Firebase and AuthRepository MUST initialize in this order (see `lib/main.dart`):
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `GetStorage.init()` - Local storage before Firebase
3. `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
4. `AuthRepository.instance.initialize()` - Singleton pattern
5. `FirebaseAppCheck.instance.activate()` - Security layer

### Creating New Features
1. Create feature folder under `lib/src/features/{feature_name}/`
2. Add models in `domain/` with `toJson()`/`fromSnapshot()` methods
3. Create repository in `data/` extending pattern from `billing_repository.dart`
4. Define Riverpod providers in  `providers/`
5. Build UI screens in `presentation/`
6. Wire providers in `app.dart` if needed for initial routing

## Project-Specific Conventions

### Model Serialization
All models must implement:
```dart
Map<String, dynamic> toJson() // For Firestore writes
factory Model.fromSnapshot(DocumentSnapshot doc) // For Firestore reads
factory Model.fromJson(Map<String, dynamic> json) // For nested objects
```
Example: `lib/src/features/billing/domain/bill_model.dart`

### Billing System Logic
- **Due date**: 7 days after month end (e.g., Oct bill due Nov 7)
- **Grace period**: 7 days after due date
- **Late fees**: ₱150/week after grace period (calculated via `LateFeeDetails.calculate()`)
- **Partial payments**: Use `allocations` array to track which categories are paid
- **Bill creation workflow**: Admin selects property → unit → enters meter readings → system auto-calculates using property rates

### Responsive Design with ScreenUtil
```dart
// Import and initialize in main.dart
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Use .w, .h, .sp for responsive sizing
Container(
  width: 300.w,         // Responsive width
  height: 200.h,        // Responsive height  
  child: Text('Test', style: TextStyle(fontSize: 16.sp)) // Responsive font
)
```
**Tablet handling**: Navigation adapts (rail vs bottom nav) based on screen width and orientation.

### Theme System
- Material 3 with 6 contrast modes (light/dark × standard/medium/high)
- Active theme: `AppTheme.lightMediumContrast` / `AppTheme.darkMediumContrast`
- Theme mode: `ThemeMode.system` (follows device)
- Custom fonts: Montserrat (main), Poppins (alt) - defined in `lib/src/theme/app_theme.dart`
- Never hardcode colors - use `Theme.of(context).colorScheme.primary`
- Use `lib/src/core/snackbars/loaders.dart` for handling snackbars

### Error Handling
Custom exceptions in `lib/src/core/exceptions/`:
- `firebase_auth_exceptions.dart` - Auth errors
- `firebase_exceptions.dart` - Firestore errors
- `format_exceptions.dart` - Data format errors
- `platform_exceptions.dart` - Platform-specific errors
Always catch specific exceptions in repositories, re-throw with user-friendly messages.
- Use `lib/src/core/snackbars/loaders.dart` for handling snackbars

## Integration Points

### Firebase Services
- **Authentication**: `firebase_auth` for email/password (admin approval workflow in `AuthRepository`)
- **Firestore**: All CRUD via repositories with `StreamProvider` for reactive UI
- **Storage**: `firebase_storage` for profile pictures and payment proofs (path: `payments/{userId}/{timestamp}`)
- **App Check**: Enabled for production security (currently `AndroidProvider.debug`)

### Local Storage (GetStorage)
Used for:
- Onboarding completion flag (`OnboardingRepository`)
- User preferences/cache
- Access: `final storage = GetStorage(); storage.write('key', value);`

### Dependencies to Know
- `iconsax: ^0.0.8` - Primary icon set (use `Iconsax.home`, not `Icons.home`)
- `smooth_page_indicator` - Onboarding page indicators
- `image_picker` + `image_cropper` - Profile/payment image uploads
- `connectivity_plus` - Network status checks before Firebase calls

## Documentation References
- **BILLING_IMPLEMENTATION_GUIDE.md** - Complete billing workflow with code examples
- **BILLING_DATABASE_STRUCTURE.md** - Full Firestore schema with JSON examples
- **IMPLEMENTATION_CHECKLIST.md** - Current phase status and TODO items
- **CONSUMPTION_ANALYTICS_GUIDE.md** - Analytics feature (planned, not implemented)
- **USER_PROFILE_IMPLEMENTATION.md** - Profile management patterns

## Documentation Management Guidelines

### When to Create New Documentation
**Only create new markdown files for:**
1. **Major new features** - Substantial features requiring comprehensive guides (e.g., new payment gateway integration, analytics dashboard)
2. **Complex architectural patterns** - New patterns not covered in existing docs
3. **External integrations** - Third-party service integrations requiring detailed setup

**Do NOT create new documentation for:**
- Minor feature updates or bug fixes
- Changes to existing features
- Code optimizations or refactoring
- Small UI updates

### When Asked to Update Documentation
**Process:**
1. **Scan existing documentation** - Use `file_search` to find all relevant `.md` files
2. **Read related files** - Check copilot-instructions.md, database structure docs, implementation guides
3. **Identify affected sections** - Determine which docs need updates based on code changes
4. **Update in-place** - Modify existing documentation rather than creating new files
5. **Maintain consistency** - Ensure all updated docs align with each other

**Key Documentation Files to Check:**
- `.github/copilot-instructions.md` - Always update for architectural changes
- `docs/database/billing-structure.md` - Update for Firestore schema changes
- `docs/guides/implementation-checklist.md` - Update for completed features
- Feature-specific docs in `docs/features/` - Update for feature changes

**Update Pattern:**
- Add "Last Updated: [Date]" timestamps to modified sections
- Add "Recent Changes" bullets for significant updates
- Mark deprecated features with clear notes
- Maintain backward compatibility information

## Common Pitfalls to Avoid
1. **Don't bypass repositories** - All Firebase operations MUST go through repository layer
2. **Don't mutate models** - Models are immutable; use `copyWith()` for updates
3. **Check user role** - Admin features must never appear in tenant UI
4. **Handle null safely** - Use null-aware operators (`?.`, `??`) consistently
5. **Test Firebase offline** - App should handle connectivity issues gracefully
6. **Don't hardcode property data** - All rates/charges come from Firestore `Properties` collection
7. **Update last readings** - After creating a bill, always update unit's `lastReadings` for next cycle
8. **Fixed charges source** - Always read trash/wifi/parking from `Property/{id}/fixedCharges`, NOT from unit or utilityRates
9. **additionalCharges field** - BillModel has `additionalCharges` list for backward compatibility but it's always empty - use `paymentBreakdown` instead

## Current Development Phase
**Phase 2 Complete**:
- ✅ Billing repository with 15+ methods
- ✅ Property/unit queries for admin bill creation
- ✅ Partial payment tracking with allocations
- ✅ Late fee auto-calculation system

**October 2025 Optimizations**:
- ✅ Fixed charges unified at property level (trash, wifi, parking)
- ✅ Removed unit-level parking references from `UnitBillingInfo`
- ✅ Eliminated redundant `additionalCharges` array from bill storage (~100 bytes saved per bill)
- ✅ Added `description` field to `PaymentBreakdownItem` for additional charges context
- ✅ Fixed null safety handling for legacy bills with `additionalCharges` field
- ✅ Updated admin and tenant UI to display additional charges description

**Next Steps**: Additional features planned (see IMPLEMENTATION_CHECKLIST.md for details). When implementing new features, check documentation first and follow existing patterns from `billing` or `auth` features. Prefer inline documentation for new features rather than separate guides.

## Future Considerations
- **Deployment**: Production deployment strategy (Play Store, Firebase production config, CI/CD) will be planned in later phases

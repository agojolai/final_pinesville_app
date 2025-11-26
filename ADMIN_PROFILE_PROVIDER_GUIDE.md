# Admin Profile Provider Implementation

## Summary
Created a Riverpod provider system to display the current admin's name throughout the admin dashboard and other admin screens.

## Files Created

### 1. lib/src/features/admin/data/models/admin_model.dart
**Purpose**: Model class for admin data from Firestore

**Key Features**:
- Maps to \dmin\ collection structure
- Contains \userId\ (Firebase Auth UID), \email\, and \profile\ (firstName, lastName)
- Provides \ullName\ and \displayName\ getters
- \displayName\ falls back to email if name is empty

**Usage Example**:
\\\dart
final admin = AdminModel.fromSnapshot(doc);
print(admin.displayName); // "John Doe" or "admin@example.com"
print(admin.fullName);    // "John Doe"
\\\

### 2. \lib/src/features/admin/data/admin_repository.dart\
**Purpose**: Repository for admin-related Firestore operations

**Key Components**:

#### Provider
\\\dart
final currentAdminProvider = StreamProvider<AdminModel?>((ref) {
  // Automatically watches current Firebase Auth user
  // Returns real-time updates of admin profile
});
\\\

#### Repository Methods
- \getCurrentAdminStream(userId)\ - Real-time admin profile updates
- \getCurrentAdmin(userId)\ - One-time fetch
- \updateAdminProfile(...)\ - Update admin name

## How to Use in UI

### Basic Usage (Dashboard Welcome)
\\\dart
import '../data/admin_repository.dart';

class MyAdminScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(currentAdminProvider);
    
    return adminAsync.when(
      data: (admin) => Text('Welcome, \'),
      loading: () => Text('Welcome, Admin'),
      error: (_, __) => Text('Welcome, Admin'),
    );
  }
}
\\\

### Access Admin Data Directly
\\\dart
final adminAsync = ref.watch(currentAdminProvider);

if (adminAsync.hasValue && adminAsync.value != null) {
  final admin = adminAsync.value!;
  print('Admin ID: \');
  print('Full Name: \');
  print('Email: \');
  print('User ID: \'); // Firebase Auth UID
}
\\\

### Use in AppBar
\\\dart
AppBar(
  title: Consumer(
    builder: (context, ref, child) {
      final adminAsync = ref.watch(currentAdminProvider);
      return Text(
        adminAsync.maybeWhen(
          data: (admin) => 'Hello, \',
          orElse: () => 'Admin Panel',
        ),
      );
    },
  ),
)
\\\

### Use in Drawer/Navigation
\\\dart
Drawer(
  child: Column(
    children: [
      Consumer(
        builder: (context, ref, child) {
          final adminAsync = ref.watch(currentAdminProvider);
          return UserAccountsDrawerHeader(
            accountName: Text(
              adminAsync.maybeWhen(
                data: (admin) => admin?.fullName ?? 'Admin',
                orElse: () => 'Admin',
              ),
            ),
            accountEmail: Text(
              adminAsync.maybeWhen(
                data: (admin) => admin?.email ?? '',
                orElse: () => '',
              ),
            ),
          );
        },
      ),
      // ... drawer items
    ],
  ),
)
\\\

## Integration Points

### Already Updated
1.  **Admin Dashboard** (\dmin_dashboard_screen.dart\)
   - Welcome section now shows admin name
   - Falls back gracefully if name not available

2.  **Bill Creation** (\illing_repository.dart\)
   - \generatedBy\ field stores admin name instead of UID
   - Uses inline query (appropriate for one-time use)

### Can Be Enhanced (Optional)
1. **Admin Navigation Drawer** - Add admin profile header
2. **Admin AppBars** - Show logged-in admin name
3. **Admin Activity Logs** - Store admin name with actions
4. **Admin Profile Screen** - Allow name editing

## Provider Benefits

### Why Use This Provider?

1. **Real-time Updates**: If admin updates their name in Firestore, UI updates automatically
2. **Single Source of Truth**: No duplicate queries across components
3. **Automatic Caching**: Riverpod caches the data, reducing Firestore reads
4. **Auth Integration**: Automatically tracks current Firebase Auth user
5. **Type Safety**: Strong typing prevents null errors

### When NOT to Use Provider

- **One-time operations** (like bill creation) - Direct query is fine
- **Background jobs** (Cloud Functions) - Use Admin SDK directly
- **Non-UI code** - Use repository methods directly

## Firestore Structure Required

The provider expects this structure in the \dmin\ collection:

\\\json
{
  "userId": "firebase-auth-uid-here",
  "email": "admin@example.com",
  "profile": {
    "firstName": "John",
    "lastName": "Doe"
  },
  "createdAt": "2025-10-22T10:00:00Z",
  "updatedAt": "2025-10-22T10:00:00Z"
}
\\\

## Migration Notes

If existing admin documents don't have \profile\ field:
- Provider will handle gracefully (returns empty strings)
- \displayName\ will fall back to email
- Update admin documents to add profile structure

## Testing

### Manual Test
1. Log in as admin
2. Check dashboard welcome message shows your name
3. Create a bill and verify \generatedBy\ field has admin name
4. Update admin profile in Firestore
5. Watch UI update automatically (no refresh needed)

### Debug Logs
The provider includes debug logging:
- \currentAdminProvider: No authenticated user\ - Not logged in
- \currentAdminProvider: Watching admin profile for userId: ...\ - Tracking user
- \No admin found for userId: ...\ - Admin doc missing userId field

## Future Enhancements

1. **Admin Profile Settings Screen** - Let admins update their name
2. **Admin Avatar Upload** - Add profile picture support
3. **Role-Based Permissions** - Add \ole\ field (super admin, manager, etc.)
4. **Admin Activity Tracking** - Log all admin actions with name/timestamp

---

**Last Updated**: October 22, 2025
**Status**:  Implemented and working

# User Profile and Account Settings Implementation

This implementation adds comprehensive user profile and account settings features to the Pinesville app, including occupant management functionality.

## Features Implemented

### 1. User Profile Management
- **Real-time user data**: ProfileScreen now displays actual user data from Firestore
- **Loading states**: Proper loading indicators while fetching user data
- **Error handling**: Error states with retry options
- **Profile fields**: Display of name, email, phone, unit, move-in date, and profile picture

### 2. Account Settings
- **Contact Information**: Edit email and phone number with validation
- **Selective updates**: Only modified fields are updated in Firestore (not full object replacement)
- **Real-time sync**: Changes are immediately reflected in the UI

### 3. Occupant Management
- **Add occupants**: Add new occupants to user's subcollection
- **Edit occupants**: Modify existing occupant information
- **Delete occupants**: Remove occupants with confirmation dialog
- **Real-time updates**: Occupant list updates immediately after changes
- **Admin approval workflow**: Maintains existing approval logic for multiple occupants

## Technical Implementation

### Data Models

#### UserModel
- Maintains existing nested structure: `profile`, `property`, `account`
- Supports partial updates through `updateUserProfileField` method
- Proper serialization to/from Firestore documents

#### OccupantModel
```dart
class OccupantModel {
  final String? id;
  final String occupantName;
  final String occupantPhone;
}
```

### Repository Layer

#### UserRepository Extensions
- `updateUserProfileField(Map<String, dynamic> fields)`: Update specific profile fields
- `addOccupant(OccupantModel occupant)`: Add occupant to subcollection
- `updateOccupant(String id, OccupantModel occupant)`: Update existing occupant
- `deleteOccupant(String id)`: Delete occupant
- `fetchOccupants()`: Get all occupants for current user
- `streamOccupants()`: Real-time stream of occupants

### State Management (Riverpod)

#### Providers
- `userProfileProvider`: Streams current user profile data
- `occupantsProvider`: Streams current user's occupants
- `userProfileNotifierProvider`: State notifier for profile updates
- `occupantsNotifierProvider`: State notifier for occupant management

### UI Components

#### ProfileScreen
- **ConsumerStatefulWidget**: Uses Riverpod for state management
- **Dynamic data binding**: Real user data instead of hardcoded values
- **Loading/error states**: Proper async state handling

#### AccountSettingsScreen
- **Real save functionality**: Actual Firestore updates
- **Form validation**: Client-side validation before saving
- **Loading indicators**: UI feedback during async operations
- **Error handling**: User-friendly error messages

## Firestore Structure

### Users Collection
```
/Users/{userId}/
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
└── account/
    ├── status: string
    └── createdAt: timestamp
```

### Occupants Subcollection
```
/Users/{userId}/occupants/{occupantId}/
├── occupantName: string
└── occupantPhone: string
```

## Key Benefits

1. **Minimal Code Changes**: Leverages existing models and patterns
2. **Type Safety**: Full TypeScript-like type safety with Dart
3. **Real-time Updates**: Automatic UI updates when data changes
4. **Error Resilience**: Comprehensive error handling and user feedback
5. **Performance**: Only updates changed fields, reducing Firestore writes
6. **Scalability**: Clean separation of concerns and reusable providers

## Usage Examples

### Updating User Profile
```dart
final profileNotifier = ref.read(userProfileNotifierProvider.notifier);
await profileNotifier.updateProfileField({'firstName': 'John'});
```

### Managing Occupants
```dart
final occupantsNotifier = ref.read(occupantsNotifierProvider.notifier);

// Add occupant
await occupantsNotifier.addOccupant(OccupantModel(
  occupantName: 'Jane Doe',
  occupantPhone: '+1234567890',
));

// Update occupant
await occupantsNotifier.updateOccupant(occupantId, updatedOccupant);

// Delete occupant
await occupantsNotifier.deleteOccupant(occupantId);
```

### Watching User Data
```dart
Consumer(
  builder: (context, ref, child) {
    final userProfileAsync = ref.watch(userProfileProvider);
    
    return userProfileAsync.when(
      data: (user) => Text(user.fullName),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  },
)
```

## Testing

Unit tests are included for:
- UserModel serialization/deserialization
- OccupantModel functionality
- Data model equality and copyWith methods

Run tests with:
```bash
flutter test test/user_profile_test.dart
```

## Next Steps

1. Add profile picture upload functionality
2. Implement push notifications for occupant approvals
3. Add profile data validation on the server side
4. Implement caching for offline support
5. Add audit logging for profile changes
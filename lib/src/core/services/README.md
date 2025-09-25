# NetworkService Documentation

The `NetworkService` is a comprehensive utility class for handling internet connectivity checks and network-related error handling across the entire application.

## Features

- ✅ Internet connectivity checking with real server ping validation
- ✅ Automatic network error detection and user-friendly error messages  
- ✅ Cross-feature reusable network operations handling
- ✅ Riverpod integration for dependency injection
- ✅ Real-time connectivity monitoring
- ✅ BuildContext extension for easy access
- ✅ Comprehensive error type classification

## Quick Start

### 1. Basic Usage in Controllers

```dart
class MyController extends StateNotifier<MyState> {
  final Ref ref;
  MyController(this.ref) : super(MyState());
  
  Future<void> performNetworkOperation(BuildContext context) async {
    final networkService = ref.read(networkServiceProvider);
    
    // Method 1: Execute with automatic network handling
    final result = await networkService.executeWithNetworkHandling(
      context,
      () async {
        // Your network operation here (Firebase, API calls, etc.)
        return await authService.login(email, password);
      },
      noConnectionMessage: 'Please check your internet connection to continue.',
    );
    
    if (result != null) {
      // Handle success
      print('Operation succeeded: $result');
    }
    // Errors are automatically handled and shown to user
  }
}
```

### 2. Manual Connectivity Check

```dart
Future<void> manualNetworkCheck(BuildContext context) async {
  final networkService = ref.read(networkServiceProvider);
  
  // Check connectivity and automatically show error message if no connection
  final hasConnection = await networkService.checkConnectivityWithFeedback(context);
  
  if (!hasConnection) {
    return; // User already informed via snackbar
  }
  
  try {
    // Proceed with network operation
    await performApiCall();
  } catch (error) {
    // Handle errors with automatic network error detection
    networkService.showErrorWithNetworkHandling(context, error);
  }
}
```

### 3. Simple Connectivity Check

```dart
Future<bool> isOnline() async {
  final networkService = NetworkService.instance;
  return await networkService.hasInternetConnection();
}
```

### 4. Using BuildContext Extension

```dart
Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: () async {
      // Easy access via context extension
      if (await context.networkService.hasInternetConnection()) {
        // Perform network operation
        performOnlineAction();
      } else {
        // Handle offline state
        showOfflineMessage();
      }
    },
    child: Text('Network Operation'),
  );
}
```

### 5. Real-time Connectivity Monitoring

```dart
Widget build(BuildContext context) {
  return StreamBuilder<List<ConnectivityResult>>(
    stream: context.networkService.connectivityStream,
    builder: (context, snapshot) {
      final isConnected = snapshot.hasData && 
                         snapshot.data!.isNotEmpty &&
                         !snapshot.data!.contains(ConnectivityResult.none);
      
      return Container(
        color: isConnected ? Colors.green : Colors.red,
        child: Text(isConnected ? 'Online' : 'Offline'),
      );
    },
  );
}
```

## Error Types Handled

The NetworkService automatically detects and provides user-friendly messages for:

- **Connection Errors**: Network unreachable, failed connections
- **Timeout Errors**: Slow connections, request timeouts  
- **Server Errors**: 500, 502, 503 server issues
- **Firebase Errors**: Firebase-specific network issues
- **General Errors**: Other network-related problems

## Integration Examples

### Login Controller (Already Implemented)
```dart
class LoginController extends StateNotifier<LoginState> {
  Future<void> login(String email, String password, BuildContext context) async {
    final networkService = ref.read(networkServiceProvider);
    
    final result = await networkService.executeWithNetworkHandling(
      context,
      () async {
        final authNotifier = ref.read(authStateProvider.notifier);
        await authNotifier.signIn(email.trim(), password.trim());
        return true;
      },
      noConnectionMessage: 'Please check your internet connection to sign in.',
    );
    
    if (result == true && context.mounted) {
      // Navigate to success page
      Navigator.pushReplacement(context, MainNavigation());
    }
  }
}
```

### Registration Controller (Implemented ✅)
```dart
class RegisterController extends StateNotifier<RegisterState> {
  final Ref ref;
  
  Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String propertyName,
    required String unitNumber,
    required DateTime moveInDate,
    required BuildContext context,
  }) async {
    state = state.copyWith(isLoading: true);
    
    final result = await ref.read(networkServiceProvider).executeWithNetworkHandling(
      context,
      () async {
        final authNotifier = ref.read(authStateProvider.notifier);
        await authNotifier.signUp(email, password);
        // Future: Store additional user data in Firestore
        return true;
      },
      noConnectionMessage: 'Internet connection required for account creation.',
    );
    
    state = state.copyWith(isLoading: false);
    
    if (result == true && context.mounted) {
      Navigator.pop(context); // Go back to login
    }
  }
}
```

### API Service Integration
```dart
class ApiService {
  final NetworkService _networkService = NetworkService.instance;
  
  Future<Map<String, dynamic>?> fetchUserData(
    BuildContext context, 
    String userId,
  ) async {
    return await _networkService.executeWithNetworkHandling(
      context,
      () async {
        final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          throw Exception('Failed to load user data');
        }
      },
      noConnectionMessage: 'Internet connection required to load user data.',
    );
  }
}
```

## Best Practices

1. **Always use `context.mounted` checks** when showing UI feedback after async operations
2. **Prefer `executeWithNetworkHandling`** for complete automatic error handling
3. **Use `checkConnectivityWithFeedback`** when you need to check connectivity before multiple operations
4. **Provide custom no-connection messages** that are specific to the operation
5. **Handle success and failure cases** appropriately in your controllers
6. **Use the Riverpod provider** (`networkServiceProvider`) for dependency injection in controllers

## Migration from Old Network Code

If you have existing network error handling code, you can replace it with NetworkService:

**Before:**
```dart
// Old duplicate connectivity checking
try {
  final connectivityResult = await Connectivity().checkConnectivity();
  if (!connectivityResult.contains(ConnectivityResult.mobile) && 
      !connectivityResult.contains(ConnectivityResult.wifi)) {
    showError('No internet connection');
    return;
  }
  await performOperation();
} catch (error) {
  // Manual error parsing
  if (error.toString().contains('network')) {
    showError('Network error');
  } else {
    showError(error.toString());
  }
}
```

**After:**
```dart
// New NetworkService approach
final result = await networkService.executeWithNetworkHandling(
  context,
  () => performOperation(),
  noConnectionMessage: 'Please check your internet connection.',
);
```

## File Locations

- **Service**: `lib/src/core/services/network_service.dart`
- **Provider**: Available via `networkServiceProvider`
- **Extension**: `NetworkServiceExtension` on `BuildContext`

## Dependencies

- `connectivity_plus`: For connectivity monitoring
- `flutter_riverpod`: For state management and dependency injection
- Built-in `dart:io`: For internet reachability testing
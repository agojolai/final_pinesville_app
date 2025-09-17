import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../snackbars/loaders.dart';

// Riverpod provider for NetworkService
final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService.instance;
});

/// Network service utility class for handling connectivity and network-related errors
/// Can be used across all features in the application
/// 
/// USAGE EXAMPLES:
/// 
/// 1. In a Controller/Service:
/// ```dart
/// class MyController extends StateNotifier<MyState> {
///   final Ref ref;
///   MyController(this.ref) : super(MyState());
///   
///   Future<void> performNetworkOperation(BuildContext context) async {
///     final networkService = ref.read(networkServiceProvider);
///     
///     // Method 1: Execute with automatic network handling
///     final result = await networkService.executeWithNetworkHandling(
///       context,
///       () async {
///         // Your network operation here
///         return await apiCall();
///       },
///       noConnectionMessage: 'Please check your internet connection to continue.',
///     );
///     
///     // Method 2: Manual connectivity check
///     if (!await networkService.checkConnectivityWithFeedback(context)) {
///       return; // Network error message already shown
///     }
///     
///     try {
///       // Your network operation here
///       await apiCall();
///     } catch (error) {
///       // Method 3: Show error with network handling
///       networkService.showErrorWithNetworkHandling(context, error);
///     }
///   }
/// }
/// ```
/// 
/// 2. Using the BuildContext extension:
/// ```dart
/// Widget build(BuildContext context) {
///   return ElevatedButton(
///     onPressed: () async {
///       if (await context.networkService.hasInternetConnection()) {
///         // Perform network operation
///       }
///     },
///     child: Text('Network Operation'),
///   );
/// }
/// ```
/// 
/// 3. Real-time connectivity monitoring:
/// ```dart
/// StreamBuilder<List<ConnectivityResult>>(
///   stream: context.networkService.connectivityStream,
///   builder: (context, snapshot) {
///     final isConnected = snapshot.hasData && 
///                        snapshot.data!.isNotEmpty &&
///                        !snapshot.data!.contains(ConnectivityResult.none);
///     return Text(isConnected ? 'Connected' : 'No Internet');
///   },
/// )
/// ```
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  /// Get the singleton instance
  static NetworkService get instance => _instance;

  /// Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      // Check if any connection type is available
      bool hasConnection = connectivityResult.contains(ConnectivityResult.mobile) ||
                          connectivityResult.contains(ConnectivityResult.wifi) ||
                          connectivityResult.contains(ConnectivityResult.ethernet) ||
                          connectivityResult.contains(ConnectivityResult.vpn);
      
      // Additional check by trying to reach a reliable server
      if (hasConnection) {
        return await _pingServer();
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Ping a reliable server to confirm internet access
  Future<bool> _pingServer() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get connectivity stream for real-time connectivity monitoring
  Stream<List<ConnectivityResult>> get connectivityStream => 
      Connectivity().onConnectivityChanged;

  /// Check connectivity and show error message if no connection
  /// Returns true if connected, false if not connected
  Future<bool> checkConnectivityWithFeedback(BuildContext context, {
    String? customMessage,
  }) async {
    final hasConnection = await hasInternetConnection();
    
    if (!hasConnection && context.mounted) {
      Loaders.errorSnackBar(
        context,
        title: 'No Internet Connection',
        message: customMessage ?? 
                'Please check your internet connection and try again.',
      );
    }
    
    return hasConnection;
  }

  /// Parse error and return appropriate network error information
  NetworkErrorInfo getNetworkErrorInfo(dynamic error) {
    String errorString = error.toString().toLowerCase();
    
    // Check for specific network-related error patterns
    if (_isNetworkError(errorString)) {
      return NetworkErrorInfo(
        isNetworkError: true,
        title: 'Connection Problem',
        message: 'Please check your internet connection or try again later. The server might be experiencing issues.',
        errorType: NetworkErrorType.connection,
      );
    }
    
    // Check for timeout errors
    if (_isTimeoutError(errorString)) {
      return NetworkErrorInfo(
        isNetworkError: true,
        title: 'Request Timed Out',
        message: 'The request is taking too long. Please check your connection and try again.',
        errorType: NetworkErrorType.timeout,
      );
    }
    
    // Check for server errors
    if (_isServerError(errorString)) {
      return NetworkErrorInfo(
        isNetworkError: true,
        title: 'Server Issue',
        message: 'Our servers are experiencing issues. Please try again in a few moments.',
        errorType: NetworkErrorType.server,
      );
    }
    
    // Check for Firebase-specific network errors
    if (_isFirebaseNetworkError(errorString)) {
      return NetworkErrorInfo(
        isNetworkError: true,
        title: 'Service Connection Issue',
        message: 'Unable to connect to our services. Please check your internet connection and try again.',
        errorType: NetworkErrorType.firebase,
      );
    }
    
    // Not a network error - return original error
    return NetworkErrorInfo(
      isNetworkError: false,
      title: 'Error',
      message: error.toString(),
      errorType: NetworkErrorType.other,
    );
  }

  /// Show error message with appropriate network handling
  void showErrorWithNetworkHandling(
    BuildContext context,
    dynamic error, {
    String? fallbackTitle,
    VoidCallback? onRetry,
  }) {
    if (!context.mounted) return;
    
    final errorInfo = getNetworkErrorInfo(error);
    
    Loaders.errorSnackBar(
      context,
      title: errorInfo.title,
      message: errorInfo.message,
    );
  }

  /// Execute a network operation with automatic error handling
  Future<T?> executeWithNetworkHandling<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? noConnectionMessage,
    bool showLoadingIndicator = false,
    VoidCallback? onRetry,
  }) async {
    try {
      // Check connectivity first
      final hasConnection = await checkConnectivityWithFeedback(
        context,
        customMessage: noConnectionMessage,
      );
      
      if (!hasConnection) return null;
      
      // Execute the operation
      return await operation();
      
    } catch (error) {
      // Handle network errors automatically
      if (context.mounted) {
        showErrorWithNetworkHandling(context, error, onRetry: onRetry);
      }
      return null;
    }
  }

  // Private helper methods for error detection
  bool _isNetworkError(String error) {
    return error.contains('network') ||
           error.contains('connection') ||
           error.contains('unreachable') ||
           error.contains('failed to connect') ||
           error.contains('socket') ||
           error.contains('host lookup failed') ||
           error.contains('no internet') ||
           error.contains('network unavailable');
  }

  bool _isTimeoutError(String error) {
    return error.contains('timeout') ||
           error.contains('timed out') ||
           error.contains('operation timed out') ||
           error.contains('connection timeout');
  }

  bool _isServerError(String error) {
    return error.contains('server') ||
           error.contains('internal server error') ||
           error.contains('service unavailable') ||
           error.contains('bad gateway') ||
           error.contains('502') ||
           error.contains('503') ||
           error.contains('500');
  }

  bool _isFirebaseNetworkError(String error) {
    return error.contains('firebase') && 
           (error.contains('network') || 
            error.contains('unavailable') ||
            error.contains('permission-denied') ||
            error.contains('unavailable'));
  }
}

/// Data class for network error information
class NetworkErrorInfo {
  final bool isNetworkError;
  final String title;
  final String message;
  final NetworkErrorType errorType;

  const NetworkErrorInfo({
    required this.isNetworkError,
    required this.title,
    required this.message,
    required this.errorType,
  });
}

/// Enum for different types of network errors
enum NetworkErrorType {
  connection,
  timeout,
  server,
  firebase,
  other,
}

/// Extension on BuildContext for easy access to NetworkService
extension NetworkServiceExtension on BuildContext {
  NetworkService get networkService => NetworkService.instance;
}
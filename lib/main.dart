import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'app.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'src/core/repositories/auth_repository.dart';
import 'src/core/utils/app_logger.dart';
import 'src/core/services/fcm_service.dart';

//Entry point of the app

Future<void> main() async {
  // Ensure widget binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  //init local storage
  await GetStorage.init();
  
  //Initialize Firebase
  AppLogger.info('Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.info('Firebase initialized successfully');
  
  // Wait a moment to ensure Firebase is fully initialized
  await Future.delayed(const Duration(milliseconds: 100));
  
  // Initialize AuthRepository singleton after Firebase is ready
  AppLogger.info('Initializing AuthRepository...');
  AuthRepository.instance.initialize();
  AppLogger.info('AuthRepository initialized successfully');
  
  // Initialize Firebase App Check for security (optional)
  await FirebaseAppCheck.instance.activate(
    // Use different providers based on platform and environment
    androidProvider: AndroidProvider.debug, // Use AndroidProvider.playIntegrity for production
  );

  // Initialize FlutterDownloader for APK downloads
  AppLogger.info('Initializing FlutterDownloader...');
  await FlutterDownloader.initialize(
    debug: true, // Set to false in production
    ignoreSsl: false, // Set to true to ignore SSL cert verification (not recommended)
  );
  AppLogger.info('FlutterDownloader initialized successfully');
  
  // Initialize Firebase Cloud Messaging
  AppLogger.info('Initializing Firebase Cloud Messaging...');
  await FCMService.initialize();
  AppLogger.info('FCM initialized successfully');

  // Initialize screen util for responsive design
  await ScreenUtil.ensureScreenSize();

  runApp(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(375, 812), // Mobile design base
        minTextAdapt: true,
        splitScreenMode: true, // Support for larger screens
        useInheritedMediaQuery: true, // Better tablet support
        builder: (context, child) => const App(),
      ),
    ),
  );
}

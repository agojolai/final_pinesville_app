import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'src/features/auth/data/auth_repository.dart';

//Entry point of the app

Future<void> main() async {
  // Ensure widget binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  //init local storage
  await GetStorage.init();
  
  //Initialize Firebase
  print('Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Firebase initialized successfully');
  
  // Wait a moment to ensure Firebase is fully initialized
  await Future.delayed(const Duration(milliseconds: 100));
  
  // Initialize AuthRepository singleton after Firebase is ready
  print('Initializing AuthRepository...');
  AuthRepository.instance.initialize();
  print('AuthRepository initialized successfully');
  
  // Initialize Firebase App Check for security (optional)
  await FirebaseAppCheck.instance.activate(
    // Use different providers based on platform and environment
    androidProvider: AndroidProvider.debug, // Use AndroidProvider.playIntegrity for production
  );

  // Initialize screen util for responsive design
  await ScreenUtil.ensureScreenSize();

  runApp(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: Size(375, 812), // Set to your design's width/height
        minTextAdapt: true,
        builder: (context, child) => const App(),
      ),
    ),
  );
}

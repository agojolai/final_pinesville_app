import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final firestore = FirebaseFirestore.instance;
  
  // Test 1: Create a test notification
  print('Creating test notification...');
  await firestore.collection('Notifications').add({
    'userId': 'test_user_123',
    'title': 'Test Notification',
    'body': 'This is a test notification to verify Firestore writes work',
    'screen': '/home',
    'type': 'test',
    'read': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
  
  print(' Test notification created successfully!');
  print('Check your Firebase Console under Firestore > Notifications collection');
}

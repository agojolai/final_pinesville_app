import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

/// Service to manage app update notifications using Upgrader package
class AppUpdateService {
  // GitHub raw URL for appcast XML file
  static const String _appcastURL = 
      'https://raw.githubusercontent.com/agojolai/final_pinesville_app/main/appcast.xml';
  
  /// Get the Upgrader instance for app update notifications
  /// All users (admin and tenant) use the same update feed
  static Upgrader getUpgrader() {
    return Upgrader(
      storeController: UpgraderStoreController(
        onAndroid: () => UpgraderAppcastStore(
          appcastURL: _appcastURL,
          osVersion: Version(1, 0, 0), // Placeholder, will be auto-detected
        ),
      ),
      debugDisplayAlways: false, // Production: Only show when update available //set to true for forced dialog display during testing
      debugLogging: false, // Production: Disable debug logs //set to true for debugging
      durationUntilAlertAgain: const Duration(days: 3),
      // Optional: Custom messages
      // messages: CustomUpgraderMessages(),
    );
  }
  
  /// Get the APK download URL from appcast
  static Future<String?> getApkDownloadUrl() async {
    try {
      final response = await http.get(Uri.parse(_appcastURL));
      print('📡 Appcast fetch status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('✅ Appcast XML fetched successfully');
        final document = xml.XmlDocument.parse(response.body);
        final enclosure = document.findAllElements('enclosure').first;
        final url = enclosure.getAttribute('url');
        print('📦 APK URL extracted: $url');
        return url;
      } else {
        print('❌ Failed to fetch appcast: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching appcast: $e');
    }
    return null;
  }
}

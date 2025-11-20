import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/utils/app_logger.dart';

/// Service to handle APK downloads and installation
class ApkDownloadService {
  /// Download APK from URL and prompt installation
  static Future<bool> downloadAndInstall(String apkUrl) async {
    try {
      AppLogger.info('Starting APK download from: $apkUrl');
      
      // Request storage permission (Android 12 and below)
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          AppLogger.error('Storage permission denied');
          return false;
        }
      }
      
      // Get download directory
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        AppLogger.error('Could not access external storage');
        return false;
      }
      
      final savePath = '${dir.path}/Downloads';
      await Directory(savePath).create(recursive: true);
      
      AppLogger.info('Download path: $savePath');
      
      // Start download
      final taskId = await FlutterDownloader.enqueue(
        url: apkUrl,
        savedDir: savePath,
        fileName: 'pinesville_update.apk',
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: true,
      );
      
      if (taskId == null) {
        AppLogger.error('Failed to start download');
        return false;
      }
      
      AppLogger.info('Download started with taskId: $taskId');
      
      // Listen for download completion
      FlutterDownloader.registerCallback((id, status, progress) {
        if (id == taskId && status == DownloadTaskStatus.complete) {
          AppLogger.info('Download completed successfully');
          _installApk('$savePath/pinesville_update.apk');
        } else if (id == taskId && status == DownloadTaskStatus.failed) {
          AppLogger.error('Download failed');
        }
      });
      
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error downloading APK: $e', stackTrace);
      return false;
    }
  }
  
  /// Install downloaded APK
  static Future<void> _installApk(String filePath) async {
    try {
      AppLogger.info('Installing APK from: $filePath');
      
      final result = await OpenFilex.open(filePath);
      
      if (result.type == ResultType.done) {
        AppLogger.info('Install prompt opened successfully');
      } else {
        AppLogger.error('Failed to open install prompt: ${result.message}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error installing APK: $e', stackTrace);
    }
  }
}

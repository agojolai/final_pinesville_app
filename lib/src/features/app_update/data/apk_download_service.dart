import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/utils/app_logger.dart';

/// Service to handle APK downloads and installation
class ApkDownloadService {
  /// Download APK from URL and prompt installation
  static Future<bool> downloadAndInstall(String apkUrl) async {
    try {
      AppLogger.info('Starting APK download from: $apkUrl');
      
      // Get download directory
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        AppLogger.error('Could not access external storage');
        return false;
      }
      
      final savePath = '${dir.path}/Downloads';
      await Directory(savePath).create(recursive: true);
      final apkPath = '$savePath/pinesville_update.apk';
      
      AppLogger.info('Download path: $savePath');
      
      // Start download
      final taskId = await FlutterDownloader.enqueue(
        url: apkUrl,
        savedDir: savePath,
        fileName: 'pinesville_update.apk',
        showNotification: true,
        openFileFromNotification: false, // We'll open it manually
        saveInPublicStorage: false,
      );
      
      if (taskId == null) {
        AppLogger.error('Failed to start download');
        return false;
      }
      
      AppLogger.info('Download started with taskId: $taskId');
      
      // Poll for download completion
      _pollDownloadStatus(taskId, apkPath);
      
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error downloading APK: $e', stackTrace);
      return false;
    }
  }
  
  /// Poll download status and open APK when complete
  static Future<void> _pollDownloadStatus(String taskId, String apkPath) async {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      
      final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE task_id='$taskId'"
      );
      
      if (tasks == null || tasks.isEmpty) continue;
      
      final task = tasks.first;
      final status = task.status;
      
      if (status == DownloadTaskStatus.complete) {
        AppLogger.info('✅ Download completed! Opening install prompt...');
        await _installApk(apkPath);
        break;
      } else if (status == DownloadTaskStatus.failed) {
        AppLogger.error('❌ Download failed');
        break;
      } else if (status == DownloadTaskStatus.canceled) {
        AppLogger.info('Download canceled');
        break;
      }
    }
  }
  
  /// Install downloaded APK
  static Future<void> _installApk(String filePath) async {
    try {
      AppLogger.info('Installing APK from: $filePath');
      
      // Verify file exists
      final file = File(filePath);
      if (!await file.exists()) {
        AppLogger.error('APK file not found at: $filePath');
        return;
      }
      
      AppLogger.info('APK file size: ${await file.length()} bytes');
      
      final result = await OpenFilex.open(filePath);
      
      if (result.type == ResultType.done) {
        AppLogger.info('✅ Install prompt opened successfully');
        
        // Delete APK after opening install prompt to free up space
        await Future.delayed(const Duration(seconds: 2)); // Small delay to ensure file is in use
        try {
          await file.delete();
          AppLogger.info('🗑️ Cleaned up APK file after installation');
        } catch (e) {
          AppLogger.info('APK file cleanup skipped (file may be in use): $e');
        }
      } else {
        AppLogger.error('❌ Failed to open install prompt: ${result.message}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error installing APK: $e', stackTrace);
    }
  }
}

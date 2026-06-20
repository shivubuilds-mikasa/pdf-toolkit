import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileUtils {
  static const String defaultFolderName = 'PDF Toolkit';

  // Get saving directory
  static Future<Directory> getSaveDirectory({String? customPath}) async {
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (await dir.exists()) {
        return dir;
      }
    }
    
    // Default fallback
    Directory baseDir;
    if (Platform.isAndroid) {
      // Use standard application documents directory or public documents
      final extDirs = await getExternalStorageDirectories(type: StorageDirectory.documents);
      if (extDirs != null && extDirs.isNotEmpty) {
        baseDir = extDirs.first;
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final saveDir = Directory('${baseDir.path}/$defaultFolderName');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return saveDir;
  }

  // Get total storage used by all files in the directory
  static Future<int> getStorageUsed({String? customPath}) async {
    try {
      final dir = await getSaveDirectory(customPath: customPath);
      int totalSize = 0;
      if (await dir.exists()) {
        final List<FileSystemEntity> files = dir.listSync();
        for (var file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
      return totalSize;
    } catch (_) {
      return 0;
    }
  }

  // Format bytes size to readable string
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  // List all files in the directory
  static Future<List<File>> listSavedPdfs({String? customPath}) async {
    try {
      final dir = await getSaveDirectory(customPath: customPath);
      if (await dir.exists()) {
        final entities = dir.listSync();
        return entities
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.pdf'))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // Rename a file
  static Future<File?> renameFile(File file, String newName) async {
    try {
      final String path = file.path;
      final int lastSeparator = path.lastIndexOf(Platform.pathSeparator);
      final String directoryPath = path.substring(0, lastSeparator);
      
      // Ensure it has .pdf extension
      String cleanName = newName;
      if (!cleanName.toLowerCase().endsWith('.pdf')) {
        cleanName = '$cleanName.pdf';
      }

      final String newPath = '$directoryPath${Platform.pathSeparator}$cleanName';
      final renamedFile = await file.rename(newPath);
      return renamedFile;
    } catch (_) {
      return null;
    }
  }

  // Share a file
  static Future<void> shareFile(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)], text: 'PDF Toolkit generated document.');
    } catch (_) {}
  }

  // Delete a file
  static Future<bool> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

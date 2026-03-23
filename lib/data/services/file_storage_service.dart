import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Manages local photo storage organized by season
class FileStorageService {
  /// Get the base directory for app data
  Future<Directory> _getBaseDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final baseDir = Directory(p.join(appDir.path, 'app_data'));
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    return baseDir;
  }

  /// Get the directory for a specific season and photo type
  Future<Directory> _getSeasonDir(String seasonId, String type) async {
    final baseDir = await _getBaseDir();
    final folder = type == 'receipt' ? 'receipts' : 'products';
    final dir = Directory(p.join(baseDir.path, seasonId, folder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copy a file (from camera/gallery temp) to the app's permanent storage
  /// Returns the new file path
  Future<String> savePhoto({
    required String sourcePath,
    required String seasonId,
    required String type,
    required String fileName,
  }) async {
    final dir = await _getSeasonDir(seasonId, type);
    final destPath = p.join(dir.path, fileName);
    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);
    return destPath;
  }

  /// Delete a photo file from local storage
  Future<void> deletePhoto(String localPath) async {
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Delete all photos for a season (when deleting a season)
  Future<void> deleteSeasonPhotos(String seasonId) async {
    final baseDir = await _getBaseDir();
    final seasonDir = Directory(p.join(baseDir.path, seasonId));
    if (await seasonDir.exists()) {
      await seasonDir.delete(recursive: true);
    }
  }
}

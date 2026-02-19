import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/episode.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';

class DownloadService {
  static final DownloadService instance = DownloadService._internal();
  DownloadService._internal();

  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _activeDownloads = {};

  // Get download progress for an episode
  double getProgress(String episodeId) {
    return _downloadProgress[episodeId] ?? 0.0;
  }

  // Check if episode is being downloaded
  bool isDownloading(String episodeId) {
    return _activeDownloads[episodeId] ?? false;
  }

  // Get downloads directory
  Future<Directory> _getDownloadsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(
      path.join(appDir.path, StorageConstants.downloadsFolderName),
    );

    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    return downloadsDir;
  }

  // Download episode
  Future<String?> downloadEpisode(
    Episode episode,
    Function(double)? onProgress,
  ) async {
    if (_activeDownloads[episode.id] == true) {
      logger.w('Episode is already being downloaded: ${episode.title}');
      return null;
    }

    try {
      _activeDownloads[episode.id] = true;
      _downloadProgress[episode.id] = 0.0;

      // Get downloads directory
      final downloadsDir = await _getDownloadsDirectory();

      // Create filename from episode title and audio URL
      final extension = path.extension(Uri.parse(episode.audioUrl).path);
      final sanitizedTitle = episode.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      final filename = '${episode.id}_$sanitizedTitle$extension';
      final filePath = path.join(downloadsDir.path, filename);

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        logger.i('File already exists: $filePath');
        _activeDownloads[episode.id] = false;
        return filePath;
      }

      // Download file
      final request = http.Request('GET', Uri.parse(episode.audioUrl));
      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('Failed to download: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      var downloadedBytes = 0;

      final sink = file.openWrite();

      await for (var chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (contentLength > 0) {
          final progress = downloadedBytes / contentLength;
          _downloadProgress[episode.id] = progress;
          onProgress?.call(progress);
        }
      }

      await sink.close();

      _activeDownloads[episode.id] = false;
      _downloadProgress[episode.id] = 1.0;

      logger.i('Download completed: $filePath');
      return filePath;
    } catch (e) {
      logger.e('Error downloading episode', error: e);
      _activeDownloads[episode.id] = false;
      _downloadProgress.remove(episode.id);
      return null;
    }
  }

  // Delete downloaded episode
  Future<bool> deleteDownload(String localFilePath) async {
    try {
      final file = File(localFilePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      logger.e('Error deleting download', error: e);
      return false;
    }
  }

  // Get total size of downloads
  Future<int> getTotalDownloadSize() async {
    try {
      final downloadsDir = await _getDownloadsDirectory();
      var totalSize = 0;

      await for (var entity in downloadsDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      logger.e('Error calculating download size', error: e);
      return 0;
    }
  }

  // Clear all downloads
  Future<void> clearAllDownloads() async {
    try {
      final downloadsDir = await _getDownloadsDirectory();

      await for (var entity in downloadsDir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    } catch (e) {
      logger.e('Error clearing downloads', error: e);
    }
  }
}

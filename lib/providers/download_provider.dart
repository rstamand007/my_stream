import 'package:flutter/material.dart';
import '../models/episode.dart';
import '../services/download_service.dart';
import '../services/database_service.dart';

class DownloadProvider with ChangeNotifier {
  final DownloadService _downloadService = DownloadService.instance;
  final DatabaseService _db = DatabaseService.instance;

  List<Episode> _downloadedEpisodes = [];
  Map<String, double> _downloadProgress = {};

  // Getters
  List<Episode> get downloadedEpisodes => _downloadedEpisodes;

  double getProgress(String episodeId) {
    return _downloadProgress[episodeId] ?? 0.0;
  }

  bool isDownloading(String episodeId) {
    return _downloadService.isDownloading(episodeId);
  }

  bool isDownloaded(String episodeId) {
    return _downloadedEpisodes.any((e) => e.id == episodeId);
  }

  // Initialize
  Future<void> init() async {
    await loadDownloadedEpisodes();
  }

  // Load downloaded episodes from database
  Future<void> loadDownloadedEpisodes() async {
    try {
      _downloadedEpisodes = await _db.getDownloadedEpisodes();
      notifyListeners();
    } catch (e) {
      print('Error loading downloaded episodes: $e');
    }
  }

  // Download episode
  Future<void> downloadEpisode(Episode episode) async {
    try {
      final filePath = await _downloadService.downloadEpisode(episode, (
        progress,
      ) {
        _downloadProgress[episode.id] = progress;
        notifyListeners();
      });

      if (filePath != null) {
        // Update episode in database
        final updatedEpisode = episode.copyWith(
          isDownloaded: true,
          localFilePath: filePath,
        );
        await _db.updateEpisode(updatedEpisode);

        // Reload downloaded episodes
        await loadDownloadedEpisodes();

        _downloadProgress.remove(episode.id);
        notifyListeners();
      }
    } catch (e) {
      print('Error downloading episode: $e');
      _downloadProgress.remove(episode.id);
      notifyListeners();
    }
  }

  // Delete download
  Future<void> deleteDownload(Episode episode) async {
    try {
      if (episode.localFilePath != null) {
        final success = await _downloadService.deleteDownload(
          episode.localFilePath!,
        );

        if (success) {
          // Update episode in database
          final updatedEpisode = episode.copyWith(
            isDownloaded: false,
            localFilePath: null,
          );
          await _db.updateEpisode(updatedEpisode);

          // Reload downloaded episodes
          await loadDownloadedEpisodes();
        }
      }
    } catch (e) {
      print('Error deleting download: $e');
    }
  }

  // Get total download size
  Future<int> getTotalDownloadSize() async {
    return await _downloadService.getTotalDownloadSize();
  }

  // Clear all downloads
  Future<void> clearAllDownloads() async {
    try {
      await _downloadService.clearAllDownloads();

      // Update all episodes in database
      for (var episode in _downloadedEpisodes) {
        final updatedEpisode = episode.copyWith(
          isDownloaded: false,
          localFilePath: null,
        );
        await _db.updateEpisode(updatedEpisode);
      }

      await loadDownloadedEpisodes();
    } catch (e) {
      print('Error clearing downloads: $e');
    }
  }
}

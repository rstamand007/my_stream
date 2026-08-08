import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/episode.dart';
import '../services/download_service.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

class DownloadProvider with ChangeNotifier, WidgetsBindingObserver {
  final DownloadService _downloadService = DownloadService.instance;
  final DatabaseService _db = DatabaseService.instance;

  List<Episode> _downloadedEpisodes = [];
  final Map<String, double> _downloadProgress = {};

  bool _isAutoplayEnabled = false;

  // Getters
  List<Episode> get downloadedEpisodes => _downloadedEpisodes;
  bool get isAutoplayEnabled => _isAutoplayEnabled;

  void toggleAutoplay(bool value) {
    _isAutoplayEnabled = value;
    notifyListeners();
  }

  double getProgress(String episodeId) {
    return _downloadProgress[episodeId] ?? 0.0;
  }

  void reorderDownloads(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _downloadedEpisodes.removeAt(oldIndex);
    _downloadedEpisodes.insert(newIndex, item);
    notifyListeners();
    _saveOrder();
  }

  Future<void> _saveOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentOrder = _downloadedEpisodes.map((e) => e.id).toList();
      await prefs.setStringList('download_playlist_order', currentOrder);
    } catch (e) {
      logger.e('Error saving download order', error: e);
    }
  }

  bool isDownloading(String episodeId) {
    return _downloadService.isDownloading(episodeId);
  }

  bool isDownloaded(String episodeId) {
    return _downloadedEpisodes.any((e) => e.id == episodeId);
  }

  // Initialize
  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    await loadDownloadedEpisodes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      logger.d('App resumed, reloading downloaded episodes');
      loadDownloadedEpisodes();
    }
  }

  // Load downloaded episodes from database
  Future<void> loadDownloadedEpisodes() async {
    try {
      final episodes = await _db.getDownloadedEpisodes();
      
      final prefs = await SharedPreferences.getInstance();
      final savedOrder = prefs.getStringList('download_playlist_order') ?? [];
      
      episodes.sort((a, b) {
        final indexA = savedOrder.indexOf(a.id);
        final indexB = savedOrder.indexOf(b.id);
        
        if (indexA != -1 && indexB != -1) {
          return indexA.compareTo(indexB);
        } else if (indexA != -1) {
          return 1; // b is new, place it first
        } else if (indexB != -1) {
          return -1; // a is new, place it first
        } else {
          return b.publishDate.compareTo(a.publishDate); // both new
        }
      });
      
      _downloadedEpisodes = episodes;
      
      // Clean up saved order to only include currently downloaded episodes
      final currentOrder = _downloadedEpisodes.map((e) => e.id).toList();
      if (!_areListsEqual(savedOrder, currentOrder)) {
        await prefs.setStringList('download_playlist_order', currentOrder);
      }
      
      notifyListeners();
    } catch (e) {
      logger.e('Error loading downloaded episodes', error: e);
    }
  }

  bool _areListsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
      logger.e('Error downloading episode', error: e);
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
      logger.e('Error deleting download', error: e);
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
      logger.e('Error clearing downloads', error: e);
    }
  }

  // Pick local files
  Future<void> pickLocalFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (file.path != null) {
            await _addLocalFile(file.path!, file.name);
          }
        }
        await loadDownloadedEpisodes();
      }
    } catch (e) {
      logger.e('Error picking local files', error: e);
    }
  }

  // Pick local directory
  Future<void> pickLocalDirectory() async {
    try {
      final String? selectedDirectory = await FilePicker.platform
          .getDirectoryPath();

      if (selectedDirectory != null) {
        final directory = Directory(selectedDirectory);
        final List<FileSystemEntity> entities = await directory.list().toList();

        for (var entity in entities) {
          if (entity is File && _isAudioFile(entity.path)) {
            await _addLocalFile(entity.path, path.basename(entity.path));
          }
        }
        await loadDownloadedEpisodes();
      }
    } catch (e) {
      logger.e('Error picking local directory', error: e);
    }
  }

  // Helper to add local file as an episode
  Future<void> _addLocalFile(String filePath, String fileName) async {
    final episode = Episode(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}_${fileName.hashCode}',
      podcastId: 'local',
      title: fileName,
      description: 'Local file from: $filePath',
      audioUrl: '', // Remote URL is empty for local files
      duration:
          0, // We could potentially extract this, but 0 is a safe default for now
      publishDate: DateTime.now(),
      isDownloaded: true,
      localFilePath: filePath,
    );

    await _db.insertEpisode(episode);
  }

  // Helper to check if file is audio
  bool _isAudioFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ['.mp3', '.m4a', '.wav', '.ogg', '.flac'].contains(ext);
  }
}

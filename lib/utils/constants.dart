import 'package:flutter/material.dart';

// API Endpoints
class ApiConstants {
  static const String itunesSearchUrl = 'https://itunes.apple.com/search';
  static const String itunesLookupUrl = 'https://itunes.apple.com/lookup';
}

// App Colors
class AppColors {
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF8B5CF6); // Purple
  static const Color accent = Color(0xFFEC4899); // Pink

  static const Color background = Color(0xFF0F172A); // Dark blue-gray
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceLight = Color(0xFF334155);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}

// App Durations
class AppDurations {
  static const Duration skipForward = Duration(seconds: 30);
  static const Duration skipBackward = Duration(seconds: 15);
  static const Duration searchDebounce = Duration(milliseconds: 500);
}

// Database
class DatabaseConstants {
  static const String databaseName = 'podcast_player.db';
  static const int databaseVersion = 1;

  // Table names
  static const String podcastsTable = 'podcasts';
  static const String episodesTable = 'episodes';
  static const String playbackHistoryTable = 'playback_history';
}

// Storage
class StorageConstants {
  static const String downloadsFolderName = 'podcast_downloads';
  static const String prefsThemeKey = 'theme_mode';
  static const String prefsAutoDownloadKey = 'auto_download';
  static const String prefsDownloadQualityKey = 'download_quality';
}

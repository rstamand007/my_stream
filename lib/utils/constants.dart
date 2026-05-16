// API Endpoints
class ApiConstants {
  static const String itunesSearchUrl = 'https://itunes.apple.com/search';
  static const String itunesLookupUrl = 'https://itunes.apple.com/lookup';
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

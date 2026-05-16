// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Stream';

  @override
  String get library => 'Library';

  @override
  String get search => 'Search';

  @override
  String get downloads => 'Downloads';

  @override
  String get settings => 'Settings';

  @override
  String get myLibrary => 'My Library';

  @override
  String get noPodcasts => 'No podcasts yet';

  @override
  String get searchToStart => 'Search for podcasts to get started';

  @override
  String get searchPodcasts => 'Search Podcasts';

  @override
  String get searchHint => 'Search for podcasts...';

  @override
  String get findShows => 'Find your favorite shows';

  @override
  String get noResults => 'No results found';

  @override
  String get tryDifferentSearch => 'Try a different search term';

  @override
  String get clearAllDownloads => 'Clear all downloads';

  @override
  String get noDownloads => 'No downloads yet';

  @override
  String get downloadedAppearHere => 'Downloaded episodes appear here';

  @override
  String get storageUsed => 'Storage Used';

  @override
  String get clearDownloadsTitle => 'Clear All Downloads';

  @override
  String get clearDownloadsConfirm =>
      'Are you sure you want to delete all downloaded episodes? This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get clearAll => 'Clear All';

  @override
  String get subscribed => 'Subscribed';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get about => 'About';

  @override
  String get episodes => 'Episodes';

  @override
  String get noEpisodes => 'No episodes available';

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get noEpisodePlaying => 'No episode playing';

  @override
  String get playback => 'Playback';

  @override
  String get playbackSpeed => 'Default Playback Speed';

  @override
  String get skipForward => 'Skip Forward';

  @override
  String get skipBackward => 'Skip Backward';

  @override
  String get autoDownload => 'Auto Download';

  @override
  String get autoDownloadSubtitle => 'Automatically download new episodes';

  @override
  String get downloadQuality => 'Download Quality';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Open Source Licenses';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get french => 'French';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get refresh => 'Refresh';

  @override
  String lastUpdated(Object date) {
    return 'Last updated: $date';
  }

  @override
  String get addFiles => 'Add Files';

  @override
  String get addFolder => 'Add Folder';

  @override
  String get localFile => 'Local File';
}

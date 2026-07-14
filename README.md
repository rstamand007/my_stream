# My Stream - Podcast Player

A modern podcast player application built with Flutter for Android and cross-platform targets, offering seamless online streaming, subscription management, offline downloads, and background audio playback.

## Features

- 🔍 **Podcast Search & Discovery** - Search and explore podcasts globally using the iTunes Search API integration.
- 📚 **Subscription Management** - Subscribe to your favorite shows to build a personalized library with offline caching.
- 🎵 **Advanced Audio Playback** - Background audio playback utilizing `just_audio` and `audio_service` with skip controls and flexible speed adjustment (0.5x - 2.0x).
- 📥 **Offline Download Manager** - Download episodes for offline listening, with custom configurable options like autoplay (automatically play next downloaded episode) and auto-deletion of completed episodes upon completion.
- 🎨 **Adaptive Theme & Premium UI** - Built with Material Design 3 supporting Dark, Light, and System theme synchronization. Features custom neumorphic interactive control elements and modern gradients.
- 🌐 **Multi-Language Support (Localization)** - Fully localized in English (`en`) and French (`fr`) with dynamic language switching in settings.
- 💾 **Local Storage** - Fast and reliable data caching using a Hive database with custom TypeAdapters.

## Screenshots

*Coming soon*

---

## Getting Started

### Prerequisites

- **Flutter SDK:** 3.10.4 or higher
- **Dart SDK:** 3.11.0 or higher
- **Android SDK:** API level 21 or higher (Min SDK 21)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/rstamand/my_stream.git
   cd my_stream
   ```

2. **Retrieve project dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate Hive code adapters:**
   Ensure generated files (like adapters for `Episode` and `Podcast` models) are updated:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application:**
   ```bash
   flutter run
   ```

### Building the Release APK

To package the application for Android:
```bash
flutter build apk --release
```

---

## Architecture

The project is structured according to clean architecture guidelines to keep logic separated and testable:

```
lib/
├── l10n/              # App localization support (English & French)
├── models/            # Hive database entities (Podcast & Episode)
├── providers/         # ChangeNotifier providers for state management
├── screens/           # UI screen widgets
├── services/          # Local storage, player service, downloads, & APIs
├── theme/             # Light & dark app colors and theme configurations
├── utils/             # Formatters, logs, and global constants
└── widgets/           # Shared reusable components and custom layouts
```

### Components

- **Models:**
  - [Podcast](file:///home/rstamand/Dev/flutter/my_stream/lib/models/podcast.dart) - Represents a show, annotated with Hive adapters.
  - [Episode](file:///home/rstamand/Dev/flutter/my_stream/lib/models/episode.dart) - Represents an individual podcast episode.
- **Providers (State Management):**
  - [PodcastProvider](file:///home/rstamand/Dev/flutter/my_stream/lib/providers/podcast_provider.dart) - Manages show lists, subscriptions, and details.
  - [PlayerProvider](file:///home/rstamand/Dev/flutter/my_stream/lib/providers/player_provider.dart) - Controls audio player state, timeline, speed, and history.
  - [DownloadProvider](file:///home/rstamand/Dev/flutter/my_stream/lib/providers/download_provider.dart) - Manages active downloads and queued files.
  - [LocaleProvider](file:///home/rstamand/Dev/flutter/my_stream/lib/providers/locale_provider.dart) - Handles user-selected application language.
  - [ThemeProvider](file:///home/rstamand/Dev/flutter/my_stream/lib/providers/theme_provider.dart) - Configures app themes dynamically.
- **Services (Business Logic / Infra):**
  - [DatabaseService](file:///home/rstamand/Dev/flutter/my_stream/lib/services/database_service.dart) - Local caching and CRUD using Hive.
  - [AudioPlayerService](file:///home/rstamand/Dev/flutter/my_stream/lib/services/audio_player_service.dart) & [MyStreamAudioHandler](file:///home/rstamand/Dev/flutter/my_stream/lib/services/audio_handler.dart) - Interfaces with the OS to handle media keys and audio focus.
  - [DownloadService](file:///home/rstamand/Dev/flutter/my_stream/lib/services/download_service.dart) - Handles buffered background files storage.
  - [PodcastApiService](file:///home/rstamand/Dev/flutter/my_stream/lib/services/podcast_api_service.dart) - Fetches search results and parsing feeds.

---

## Core Dependencies

Key packages utilized in the project:
* State Management: `provider`
* Audio Playback: `just_audio` & `audio_service`
* Database: `hive` & `hive_flutter`
* API & Feeds: `podcast_search` & `webfeed_revised`
* Caching: `cached_network_image`
* Localization: `flutter_localizations`
* Utility & Settings: `shared_preferences`, `permission_handler`, `logger`, `file_picker`, `package_info_plus`

---

## License

This project is licensed under the MIT License - see the [LICENSES.md](file:///home/rstamand/Dev/flutter/my_stream/LICENSES.md) file for details.

## Author

- **R. St-Amand** (Owner)

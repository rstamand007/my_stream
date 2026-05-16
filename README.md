# My Stream - Podcast Player

A modern podcast player application built with Flutter for Android.

## Features

- 🔍 **Podcast Search** - Search and discover podcasts using iTunes API
- 📚 **Subscription Management** - Subscribe to your favorite podcasts
- 🎵 **Audio Playback** - Background audio playback with speed control
- 📥 **Offline Support** - Download episodes for offline listening
- 🎨 **Modern UI** - Material Design 3 dark theme
- ⏱️ **Playback Controls** - Skip forward/backward, speed adjustment (0.5x - 2.0x)
- 💾 **Local Storage** - SQLite database for offline access

## Screenshots

_Coming soon_

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Android SDK
- Dart SDK

### Installation

1. Clone the repository:
```bash
git clone https://github.com/rstamand/my_stream.git
cd my_stream
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Build APK

```bash
flutter build apk --release
```

## Architecture

The app follows a clean architecture pattern with:

- **Models** - Data models for Podcast and Episode
- **Services** - Database, API, Audio Player, and Download services
- **Providers** - State management using Provider package
- **Screens** - UI screens for different app sections
- **Widgets** - Reusable UI components

## Dependencies

- `just_audio` - Audio playback
- `audio_service` - Background audio support
- `provider` - State management
- `sqflite` - Local database
- `podcast_search` - iTunes API integration
- `cached_network_image` - Image caching

## License

This project is licensed under the MIT License.

## Author

Built with ❤️ using Flutter

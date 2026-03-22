# Release Notes

## [v1.0.0] - Latest Changes
- **Logging**: Replaced all `print` debug statements with a formal logging mechanism using the `logger` package.
- **Enhanced Downloads Management**:
  - Implemented **Reorderable Downloads** via drag-and-drop in the Downloads screen.
  - Added **Autoplay** support for sequential playback of downloaded episodes.
  - Enabled **Local File & Directory Import** to add external audio files as episodes.
  - Added **Automatic Cleanup** which deletes downloaded episodes from storage after playback completion.
- **Audio Playback**: Implemented background audio playback support.
- **Bug Fixes**: Resolved infinite loop issue in RSS feed parsing.
- **Testing**: Improved test coverage and fixed failing unit tests.

## Features & Improvements
### Audio & Playback
- Added background playback support using `audio_service`.
- Fixed audio session initialization.
- Added skipping (forward/backward) and playback speed controls.

### Storage & Data
- Migrated database from SQLite to Hive for better performance and Flutter integration.
- Improved handling of downloaded episodes and file storage.
- Added RSS feed refresh mechanism.

### UI & UX
- Implemented a custom splash screen with river background and animations.
- Added Theme management (Light/Dark mode) using `ThemeProvider`.
- Integrated Localization (L10n) basics for multi-language support.
- **Enhanced Downloads Screen**: Added reordering, autoplay toggle, and local file/folder pickers.
- Refined Home and Podcast Detail screens.

### Developer Experience
- Transitioned from manual `print` statements to structured logging.
- Fixed various static analysis and initialization bugs.

---
*Initial Release: Flutter podcast player with search, subscriptions, playback, and offline support.*

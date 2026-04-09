# Release Notes

## [v1.0.2] - 2026-04-05
### UI & Visual Experience
- **New App Icon**: Replaced the default launcher icon with a modern, minimalist **blue wave design** in a square frame for a more professional look.
- **Dynamic Episode Artwork**: Enhanced the **Now Playing** screen to display actual episode or podcast artwork instead of generic placeholders.
- **Artwork Caching**: Integrated `CachedNetworkImage` for smooth, efficient loading and offline availability of episode covers.
- **Description Overlay**: Refined the artwork overlay on the player screen to ensure show descriptions remain readable over diverse artwork colors.

### Data & Metadata
- **Enhanced RSS Parsing**: Updated the parsing engine to extract high-resolution `itunes:image` metadata from podcast feeds.
- **Data Model Update**: Expanded the `Episode` model to support and persist artwork URLs across sessions.

## [v1.0.1] - 2026-03-22
### Bug Fixes
- **Download Crash**: Fixed a critical issue where URL-based episode IDs caused crashes on Android due to invalid filename characters.
- **Playback Format**: Resolved `UnrecognizedInputFormatException` by adding `User-Agent` headers to download requests, ensuring providers serve valid audio data.

### Optimizations
- **AudioPlayerService**: Refactored for better performance and readability, including centralized null-safety and cached stream handlers.
- **Resource Management**: Improved local file loading and cleaned up playback logic.

## [v1.0.0] - Initial Release / Enhanced Downloads
- **Logging**: Replaced all `print` debug statements with a formal logging mechanism.
- **Enhanced Downloads Management**:
  - Implemented **Reorderable Downloads** via drag-and-drop.
  - Added **Autoplay** for sequential playback.
  - Enabled **Local File & Directory Import**.
  - Added **Automatic Cleanup** after playback.
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

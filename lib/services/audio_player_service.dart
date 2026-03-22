import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/episode.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'audio_handler.dart';

class AudioPlayerService {
  static final AudioPlayerService instance = AudioPlayerService._internal();
  AudioPlayerService._internal();

  /// Reference to the handler initialized in main.dart
  MyStreamAudioHandler? _handler;
  Episode? _currentEpisode;

  // Getters
  Episode? get currentEpisode => _currentEpisode;

  Stream<Duration> get positionStream => _handler?.player.positionStream ?? Stream.empty();
  Stream<Duration?> get durationStream => _handler?.player.durationStream ?? Stream.empty();
  Stream<PlayerState> get playerStateStream => _handler?.player.playerStateStream ?? Stream.empty();
  Stream<double> get speedStream => _handler?.player.speedStream ?? Stream.empty();

  bool get isPlaying => _handler?.player.playing ?? false;
  Duration get position => _handler?.player.position ?? Duration.zero;
  Duration? get duration => _handler?.player.duration;
  double get speed => _handler?.player.speed ?? 1.0;

  /// Called from main.dart after AudioService.init
  void setHandler(MyStreamAudioHandler handler) {
    _handler = handler;
  }

  // Initialize (kept for provider compatibility)
  Future<void> init() async {}

  // Play episode
  Future<void> playEpisode(Episode episode, {Duration? startPosition}) async {
    logger.d('AudioPlayerService.playEpisode called for: ${episode.title}');
    if (_handler == null) {
      logger.e('AudioHandler is NULL in AudioPlayerService!');
      return;
    }

    try {
      final String url = episode.playbackUrl;
      if (url.isEmpty) {
        throw Exception('Episode has no audio URL');
      }

      final String finalUrl = url.startsWith('http')
          ? Uri.encodeFull(url)
          : url;

      logger.d('Final URL: $finalUrl');

      _currentEpisode = episode;

      // Update media item for the OS
      logger.d('Adding MediaItem to handler');
      _handler?.mediaItem.add(
        MediaItem(
          id: episode.id,
          title: episode.title,
          album: episode.podcastId,
          duration: episode.duration > 0
              ? Duration(seconds: episode.duration)
              : null,
          playable: true,
        ),
      );

      // Set audio source
      logger.d('Setting player source');
      if (finalUrl.startsWith('http')) {
        await _handler?.player.setUrl(finalUrl);
      } else {
        await _handler?.player.setAudioSource(AudioSource.uri(Uri.file(finalUrl)));
      }

      // Seek to saved position if available
      if (startPosition != null) {
        await _handler?.player.seek(startPosition);
      } else if (episode.playbackPosition != null &&
          episode.playbackPosition! > 0) {
        await _handler?.player.seek(Duration(seconds: episode.playbackPosition!));
      }

      // Start playback
      logger.d('Starting playback');
      await _handler?.play();
      logger.d('Playback started');
    } catch (e) {
      logger.e('Error playing episode: ${episode.title}', error: e);
      rethrow;
    }
  }

  // Play/Pause toggle
  Future<void> togglePlayPause() async {
    logger.d('AudioPlayerService.togglePlayPause');
    if (_handler == null) {
      logger.e('AudioHandler is NULL in togglePlayPause');
      return;
    }
    if (_handler?.player.playing ?? false) {
      await pause();
    } else {
      await play();
    }
  }

  // Play
  Future<void> play() async {
    logger.d('AudioPlayerService.play');
    await _handler?.play();
  }

  // Pause
  Future<void> pause() async {
    logger.d('AudioPlayerService.pause');
    await _handler?.pause();
  }

  // Stop
  Future<void> stop() async {
    await _handler?.stop();
    _currentEpisode = null;
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    await _handler?.seek(position);
  }

  // Skip forward
  Future<void> skipForward() async {
    if (_handler == null) return;
    final newPosition = _handler!.player.position + AppDurations.skipForward;
    final maxPosition = _handler!.player.duration ?? Duration.zero;
    await _handler!.player.seek(newPosition > maxPosition ? maxPosition : newPosition);
  }

  // Skip backward
  Future<void> skipBackward() async {
    if (_handler == null) return;
    final newPosition = _handler!.player.position - AppDurations.skipBackward;
    await _handler!.player.seek(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
  }

  // Set playback speed
  Future<void> setSpeed(double speed) async {
    await _handler?.setSpeed(speed);
  }

  // Dispose
  Future<void> dispose() async {
    await _handler?.customAction('dispose');
  }
}


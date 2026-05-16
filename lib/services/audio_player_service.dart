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

  // Private getters for safer access
  AudioPlayer get _player {
    if (_handler == null) throw Exception('AudioHandler not initialized');
    return _handler!.player;
  }

  MyStreamAudioHandler get _audioHandler {
    if (_handler == null) throw Exception('AudioHandler not initialized');
    return _handler!;
  }

  // Cached empty streams to avoid re-allocation
  static final _emptyDurationStream = Stream<Duration>.empty();
  static final _emptyNullableDurationStream = Stream<Duration?>.empty();
  static final _emptyPlayerStateStream = Stream<PlayerState>.empty();
  static final _emptyDoubleStream = Stream<double>.empty();

  // Getters
  Episode? get currentEpisode => _currentEpisode;

  Stream<Duration> get positionStream =>
      _handler?.player.positionStream ?? _emptyDurationStream;

  Stream<Duration?> get durationStream =>
      _handler?.player.durationStream ?? _emptyNullableDurationStream;

  Stream<PlayerState> get playerStateStream =>
      _handler?.player.playerStateStream ?? _emptyPlayerStateStream;

  Stream<double> get speedStream =>
      _handler?.player.speedStream ?? _emptyDoubleStream;

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

    try {
      final String url = episode.playbackUrl;
      if (url.isEmpty) throw Exception('Episode has no audio URL');

      final String finalUrl = url.startsWith('http') ? Uri.encodeFull(url) : url;
      logger.d('Final URL: $finalUrl');

      _currentEpisode = episode;

      // Update media item for the OS
      _audioHandler.mediaItem.add(
        MediaItem(
          id: episode.id,
          title: episode.title,
          album: episode.podcastId,
          duration:
              episode.duration > 0 ? Duration(seconds: episode.duration) : null,
          playable: true,
        ),
      );

      // Set audio source
      if (finalUrl.startsWith('http')) {
        await _player.setUrl(finalUrl);
      } else {
        await _player.setFilePath(finalUrl);
      }

      // Seek to saved position if available
      final seekTo =
          startPosition ??
          (episode.playbackPosition != null && episode.playbackPosition! > 0
              ? Duration(seconds: episode.playbackPosition!)
              : null);

      if (seekTo != null) {
        await _player.seek(seekTo);
      }

      // Start playback
      await _audioHandler.play();
      logger.d('Playback started');
    } catch (e) {
      logger.e('Error playing episode: ${episode.title}', error: e);
      rethrow;
    }
  }

  // Play/Pause toggle
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  // Play
  Future<void> play() => _audioHandler.play();

  // Pause
  Future<void> pause() => _audioHandler.pause();

  // Stop
  Future<void> stop() async {
    await _audioHandler.stop();
    _currentEpisode = null;
  }

  // Seek to position
  Future<void> seek(Duration position) => _audioHandler.seek(position);

  // Skip forward
  Future<void> skipForward() async {
    final newPosition = _player.position + AppDurations.skipForward;
    final maxPosition = _player.duration ?? Duration.zero;
    await _player.seek(newPosition > maxPosition ? maxPosition : newPosition);
  }

  // Skip backward
  Future<void> skipBackward() async {
    final newPosition = _player.position - AppDurations.skipBackward;
    await _player.seek(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
  }

  // Set playback speed
  Future<void> setSpeed(double speed) => _audioHandler.setSpeed(speed);

  // Dispose
  Future<void> dispose() => _audioHandler.customAction('dispose');
}

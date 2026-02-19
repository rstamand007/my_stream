import 'package:just_audio/just_audio.dart';
import '../models/episode.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class AudioPlayerService {
  static final AudioPlayerService instance = AudioPlayerService._internal();
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  Episode? _currentEpisode;

  // Getters
  AudioPlayer get player => _player;
  Episode? get currentEpisode => _currentEpisode;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<double> get speedStream => _player.speedStream;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  double get speed => _player.speed;

  // Initialize audio service
  Future<void> init() async {
    try {
      // Set up audio session for playback
      await _player.setAudioSource(AudioSource.uri(Uri.parse(''))).catchError((
        error,
      ) {
        // Ignore initial error
        return null;
      });
    } catch (e) {
      logger.e('Error initializing audio player', error: e);
    }
  }

  // Play episode
  Future<void> playEpisode(Episode episode, {Duration? startPosition}) async {
    try {
      _currentEpisode = episode;

      // Set audio source
      await _player.setUrl(episode.playbackUrl);

      // Seek to saved position if available
      if (startPosition != null) {
        await _player.seek(startPosition);
      } else if (episode.playbackPosition != null &&
          episode.playbackPosition! > 0) {
        await _player.seek(Duration(seconds: episode.playbackPosition!));
      }

      // Start playback
      await _player.play();
    } catch (e) {
      logger.e('Error playing episode', error: e);
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
  Future<void> play() async {
    await _player.play();
  }

  // Pause
  Future<void> pause() async {
    await _player.pause();
  }

  // Stop
  Future<void> stop() async {
    await _player.stop();
    _currentEpisode = null;
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

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
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  // Dispose
  Future<void> dispose() async {
    await _player.dispose();
  }
}

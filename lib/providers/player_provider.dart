import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/episode.dart';
import '../services/audio_player_service.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

class PlayerProvider with ChangeNotifier {
  final AudioPlayerService _audioService = AudioPlayerService.instance;
  final DatabaseService _db = DatabaseService.instance;

  Episode? _currentEpisode;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  String? _error;

  // Getters
  Episode? get currentEpisode => _currentEpisode;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get speed => _speed;
  String? get error => _error;
  bool get hasEpisode => _currentEpisode != null;
  bool get hasError => _error != null;

  double get progress {
    if (_duration.inMilliseconds > 0) {
      return _position.inMilliseconds / _duration.inMilliseconds;
    }
    return 0.0;
  }

  // Initialize
  Future<void> init() async {
    await _audioService.init();
    _setupListeners();
  }

  // Autoplay hook
  Future<void> Function()? onEpisodeEnded;

  void _setupListeners() {
    // Listen to player state changes
    _audioService.playerStateStream.listen((state) async {
      _isPlaying = state.playing;

      // Handle completion: transition to stop state
      if (state.processingState == ProcessingState.completed) {
        if (onEpisodeEnded != null) {
          await onEpisodeEnded!();
        } else {
          await stop();
        }
      } else {
        notifyListeners();
      }
    });

    // Listen to position changes
    _audioService.positionStream.listen((position) {
      _position = position;
      notifyListeners();

      // Save position every 5 seconds
      if (_currentEpisode != null && position.inSeconds % 5 == 0) {
        _savePlaybackPosition();
      }
    });

    // Listen to duration changes
    _audioService.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        notifyListeners();
      }
    });

    // Listen to speed changes
    _audioService.speedStream.listen((speed) {
      _speed = speed;
      notifyListeners();
    });
  }

  // Play episode
  Future<void> playEpisode(Episode episode) async {
    try {
      _error = null;
      _currentEpisode = episode;
      notifyListeners();

      await _audioService.playEpisode(episode);
    } catch (e) {
      _error = 'Failed to play episode: ${e.toString()}';
      logger.e('Error playing episode', error: e);
      notifyListeners();
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    await _audioService.togglePlayPause();
  }

  // Play
  Future<void> play() async {
    await _audioService.play();
  }

  // Pause
  Future<void> pause() async {
    await _audioService.pause();
  }

  // Stop
  Future<void> stop() async {
    await _audioService.stop();
    _currentEpisode = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }

  // Seek
  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  // Skip forward
  Future<void> skipForward() async {
    await _audioService.skipForward();
  }

  // Skip backward
  Future<void> skipBackward() async {
    await _audioService.skipBackward();
  }

  // Set playback speed
  Future<void> setSpeed(double speed) async {
    await _audioService.setSpeed(speed);
    _speed = speed;
    notifyListeners();
  }

  // Save playback position to database
  Future<void> _savePlaybackPosition() async {
    if (_currentEpisode != null) {
      try {
        await _db.savePlaybackPosition(
          _currentEpisode!.id,
          _position.inSeconds,
        );
      } catch (e) {
        logger.e('Error saving playback position', error: e);
      }
    }
  }

  @override
  void dispose() {
    _savePlaybackPosition();
    super.dispose();
  }
}

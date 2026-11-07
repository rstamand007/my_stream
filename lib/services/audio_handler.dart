import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import '../models/player_state.dart';
import '../utils/logger.dart';

class _UserAgentClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!kIsWeb) {
      request.headers['User-Agent'] =
          'MyStreamPodcastPlayer/1.0.0 (https://github.com/rstamand007/my_stream)';
    }
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

/// An [AudioHandler] that uses [SoLoud] to play audio.
/// This class bridges the Flutter app with the OS media notification and
/// lock-screen controls.
class MyStreamAudioHandler extends BaseAudioHandler {
  final SoLoud _soloud = SoLoud.instance;
  final _UserAgentClient _httpClient = _UserAgentClient();

  AudioSource? _currentSource;
  SoundHandle? _currentHandle;
  StreamSubscription<StreamSoundEvent>? _soundEventSub;
  Timer? _positionTimer;
  Timer? _duckTimer;

  bool _isPlaying = false;
  ProcessingState _processingState = ProcessingState.idle;
  Duration _position = Duration.zero;
  Duration? _duration;
  double _speed = 1.0;
  double _volume = 1.0;
  bool _playInterrupted = false;

  final BehaviorSubject<Duration> _positionController =
      BehaviorSubject<Duration>.seeded(Duration.zero);
  final BehaviorSubject<Duration?> _durationController =
      BehaviorSubject<Duration?>.seeded(null);
  final BehaviorSubject<PlayerState> _playerStateController =
      BehaviorSubject<PlayerState>.seeded(
    const PlayerState(false, ProcessingState.idle),
  );
  final BehaviorSubject<double> _speedController =
      BehaviorSubject<double>.seeded(1.0);

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<double> get speedStream => _speedController.stream;

  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration? get duration => _duration;
  double get speed => _speed;
  ProcessingState get processingState => _processingState;

  MyStreamAudioHandler() {
    logger.d('MyStreamAudioHandler constructor called');
    _init();
  }

  Future<void> _init() async {
    try {
      logger.d('MyStreamAudioHandler._init() starting');

      // Initialize SoLoud if needed
      if (!_soloud.isInitialized) {
        await _soloud.init(automaticCleanup: true);
        logger.d('SoLoud initialized');
      }

      // Configure audio session for speech/podcast playback with ducking (mobile/desktop)
      if (!kIsWeb) {
        final session = await AudioSession.instance;
        await session.configure(
          const AudioSessionConfiguration(
            avAudioSessionCategory: AVAudioSessionCategory.playback,
            avAudioSessionMode: AVAudioSessionMode.spokenAudio,
            androidAudioAttributes: AndroidAudioAttributes(
              contentType: AndroidAudioContentType.speech,
              flags: AndroidAudioFlags.none,
              usage: AndroidAudioUsage.media,
            ),
            androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
            androidWillPauseWhenDucked: false,
          ),
        );
        logger.d('AudioSession configured for speech playback with ducking');

        // Listen to audio focus and system interruptions
        session.interruptionEventStream.listen((event) async {
          logger.d(
            'Audio session interruption event: begin=${event.begin}, type=${event.type}',
          );
          if (event.begin) {
            switch (event.type) {
              case AudioInterruptionType.duck:
                _duckTimer?.cancel();
                await setVolume(0.2);
                _duckTimer = Timer(const Duration(seconds: 4), () {
                  if (_volume < 1.0) {
                    setVolume(1.0);
                  }
                });
                break;
              case AudioInterruptionType.pause:
                if (_isPlaying) {
                  logger.d('Player is playing, pausing due to interruption');
                  _playInterrupted = true;
                  await pause();
                }
                break;
              case AudioInterruptionType.unknown:
                if (_isPlaying) {
                  logger.d('Player is playing, pausing due to focus loss');
                  _playInterrupted = false;
                  await pause();
                }
                break;
            }
          } else {
            switch (event.type) {
              case AudioInterruptionType.duck:
                _duckTimer?.cancel();
                await setVolume(1.0);
                break;
              case AudioInterruptionType.pause:
                if (_playInterrupted) {
                  logger.d('Resuming playback after interruption ended');
                  _playInterrupted = false;
                  await play();
                }
                break;
              case AudioInterruptionType.unknown:
                _playInterrupted = false;
                break;
            }
          }
        });

        // Handle headphone unplugged (Becoming noisy)
        session.becomingNoisyEventStream.listen((_) async {
          logger.d(
            'Audio becoming noisy (headphones unplugged), pausing playback',
          );
          await pause();
        });
      }

      _updatePlaybackState();
      logger.d('MyStreamAudioHandler._init() completed');
    } catch (e, st) {
      logger.e(
        'ERROR in MyStreamAudioHandler._init()',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> loadSource(String urlOrPath, {Duration? startPosition}) async {
    await _cleanupCurrentSource();

    _setProcessingState(ProcessingState.loading);
    _position = startPosition ?? Duration.zero;
    _positionController.add(_position);

    try {
      if (!_soloud.isInitialized) {
        await _soloud.init(automaticCleanup: true);
      }

      final AudioSource source;
      if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
        source = await _soloud.loadUrl(
          urlOrPath,
          mode: LoadMode.disk,
          httpClient: _httpClient,
        );
      } else {
        if (kIsWeb) {
          source = await _soloud.loadAsset(
            urlOrPath,
            mode: LoadMode.memory,
          );
        } else {
          source = await _soloud.loadFile(
            urlOrPath,
            mode: LoadMode.disk,
          );
        }
      }

      _currentSource = source;
      final totalDuration = _soloud.getLength(source);
      _duration = totalDuration;
      _durationController.add(totalDuration);

      final handle = _soloud.play(
        source,
        volume: _volume,
        scale: _speed,
        paused: true,
      );
      _currentHandle = handle;

      if (startPosition != null && startPosition > Duration.zero) {
        _soloud.seek(handle, startPosition);
      }

      _soundEventSub?.cancel();
      _soundEventSub = source.soundEvents.listen((event) {
        if (event.event == SoundEventType.handleIsNoMoreValid) {
          if (_currentHandle != null && event.handle == _currentHandle) {
            _onPlaybackEnded();
          }
        }
      });

      _setProcessingState(ProcessingState.ready);
      _updatePlaybackState();
    } catch (e, st) {
      logger.e(
        'Error loading audio source in SoLoud',
        error: e,
        stackTrace: st,
      );
      _setProcessingState(ProcessingState.idle);
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    _playInterrupted = false;
    if (!kIsWeb) {
      try {
        final session = await AudioSession.instance;
        await session.setActive(true);
      } catch (e) {
        logger.w('Failed to activate AudioSession: $e');
      }
    }

    if (_currentHandle != null &&
        _soloud.getIsValidVoiceHandle(_currentHandle!)) {
      if (_processingState == ProcessingState.completed) {
        _soloud.seek(_currentHandle!, Duration.zero);
        _position = Duration.zero;
        _positionController.add(Duration.zero);
        _setProcessingState(ProcessingState.ready);
      }
      _soloud.setPause(_currentHandle!, false);
      _isPlaying = true;
      _startPositionTimer();
      _updatePlaybackState();
      _playerStateController.add(PlayerState(_isPlaying, _processingState));
    }
  }

  @override
  Future<void> pause() async {
    _playInterrupted = false;
    if (_currentHandle != null &&
        _soloud.getIsValidVoiceHandle(_currentHandle!)) {
      _soloud.setPause(_currentHandle!, true);
    }
    _isPlaying = false;
    _stopPositionTimer();
    _updatePlaybackState();
    _playerStateController.add(PlayerState(_isPlaying, _processingState));
  }

  @override
  Future<void> seek(Duration position) async {
    if (_currentHandle != null &&
        _soloud.getIsValidVoiceHandle(_currentHandle!)) {
      _soloud.seek(_currentHandle!, position);
    }
    _position = position;
    _positionController.add(position);
    _updatePlaybackState();
  }

  @override
  Future<void> stop() async {
    _playInterrupted = false;
    _duckTimer?.cancel();
    _stopPositionTimer();
    _isPlaying = false;
    if (_currentHandle != null &&
        _soloud.getIsValidVoiceHandle(_currentHandle!)) {
      _soloud.stop(_currentHandle!);
      _currentHandle = null;
    }
    _position = Duration.zero;
    _positionController.add(_position);
    _setProcessingState(ProcessingState.idle);
    _updatePlaybackState();
    _playerStateController.add(PlayerState(_isPlaying, _processingState));

    if (!kIsWeb) {
      try {
        final session = await AudioSession.instance;
        await session.setActive(false);
      } catch (e) {
        logger.w('Failed to deactivate AudioSession: $e');
      }
    }
    return super.stop();
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    if (_currentHandle != null &&
        _soloud.getIsValidVoiceHandle(_currentHandle!)) {
      _soloud.setRelativePlaySpeed(_currentHandle!, speed);
    }
    _speedController.add(speed);
    _updatePlaybackState();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    if (_currentHandle != null &&
        _soloud.getIsValidVoiceHandle(_currentHandle!)) {
      _soloud.setVolume(_currentHandle!, volume);
    }
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == 'dispose') {
      _duckTimer?.cancel();
      await _cleanupCurrentSource();
      _httpClient.close();
      if (_soloud.isInitialized) {
        _soloud.deinit();
      }
    }
  }

  void _onPlaybackEnded() {
    _stopPositionTimer();
    _isPlaying = false;
    if (_duration != null) {
      _position = _duration!;
      _positionController.add(_position);
    }
    _setProcessingState(ProcessingState.completed);
    _updatePlaybackState();
    _playerStateController.add(PlayerState(_isPlaying, _processingState));
  }

  void _startPositionTimer() {
    _stopPositionTimer();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_currentHandle != null &&
          _soloud.getIsValidVoiceHandle(_currentHandle!)) {
        final pos = _soloud.getPosition(_currentHandle!);
        _position = pos;
        _positionController.add(pos);
        _updatePlaybackState();
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> _cleanupCurrentSource() async {
    _stopPositionTimer();
    _soundEventSub?.cancel();
    _soundEventSub = null;
    if (_currentHandle != null) {
      if (_soloud.getIsValidVoiceHandle(_currentHandle!)) {
        _soloud.stop(_currentHandle!);
      }
      _currentHandle = null;
    }
    if (_currentSource != null) {
      try {
        await _soloud.disposeSource(_currentSource!);
      } catch (e) {
        logger.w('Error disposing previous audio source: $e');
      }
      _currentSource = null;
    }
  }

  void _setProcessingState(ProcessingState state) {
    _processingState = state;
    _playerStateController.add(PlayerState(_isPlaying, _processingState));
    _updatePlaybackState();
  }

  void _updatePlaybackState() {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.rewind,
          if (_isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.fastForward,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_processingState] ??
            AudioProcessingState.idle,
        playing: _isPlaying,
        updatePosition: _position,
        bufferedPosition: _position,
        speed: _speed,
      ),
    );
  }
}

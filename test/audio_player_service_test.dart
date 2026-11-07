import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_stream/models/episode.dart';
import 'package:my_stream/models/player_state.dart';
import 'package:my_stream/services/audio_handler.dart';
import 'package:my_stream/services/audio_player_service.dart';
import 'package:my_stream/utils/constants.dart';
import 'package:rxdart/rxdart.dart';

class MockMyStreamAudioHandler implements MyStreamAudioHandler {
  @override
  final BehaviorSubject<MediaItem?> mediaItem =
      BehaviorSubject<MediaItem?>.seeded(null);

  @override
  final BehaviorSubject<PlaybackState> playbackState =
      BehaviorSubject<PlaybackState>();

  final BehaviorSubject<Duration> _positionSubject =
      BehaviorSubject<Duration>.seeded(Duration.zero);
  final BehaviorSubject<Duration?> _durationSubject =
      BehaviorSubject<Duration?>.seeded(null);
  final BehaviorSubject<PlayerState> _playerStateSubject =
      BehaviorSubject<PlayerState>.seeded(
    const PlayerState(false, ProcessingState.idle),
  );
  final BehaviorSubject<double> _speedSubject =
      BehaviorSubject<double>.seeded(1.0);

  @override
  Stream<Duration> get positionStream => _positionSubject.stream;

  @override
  Stream<Duration?> get durationStream => _durationSubject.stream;

  @override
  Stream<PlayerState> get playerStateStream => _playerStateSubject.stream;

  @override
  Stream<double> get speedStream => _speedSubject.stream;

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  double _speed = 1.0;
  ProcessingState _processingState = ProcessingState.idle;

  bool loadSourceCalled = false;
  String? lastLoadedUrl;
  Duration? lastStartPosition;
  bool playCalled = false;
  bool pauseCalled = false;
  bool stopCalled = false;
  Duration? lastSeekPosition;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Duration get position => _position;

  @override
  Duration? get duration => _duration;

  @override
  double get speed => _speed;

  @override
  ProcessingState get processingState => _processingState;

  void simulatePosition(Duration pos) {
    _position = pos;
    _positionSubject.add(pos);
  }

  void simulateDuration(Duration dur) {
    _duration = dur;
    _durationSubject.add(dur);
  }

  void simulateState(bool playing, ProcessingState state) {
    _isPlaying = playing;
    _processingState = state;
    _playerStateSubject.add(PlayerState(playing, state));
  }

  @override
  Future<void> loadSource(String urlOrPath, {Duration? startPosition}) async {
    loadSourceCalled = true;
    lastLoadedUrl = urlOrPath;
    lastStartPosition = startPosition;
    _processingState = ProcessingState.ready;
  }

  @override
  Future<void> play() async {
    playCalled = true;
    _isPlaying = true;
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    _isPlaying = false;
  }

  @override
  Future<void> seek(Duration pos) async {
    lastSeekPosition = pos;
    _position = pos;
    _positionSubject.add(pos);
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
    _isPlaying = false;
    _position = Duration.zero;
  }

  @override
  Future<void> setSpeed(double spd) async {
    _speed = spd;
    _speedSubject.add(spd);
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AudioPlayerService service;
  late MockMyStreamAudioHandler mockHandler;

  final testEpisode = Episode(
    id: 'ep-1',
    podcastId: 'pod-1',
    title: 'Test Episode',
    description: 'Test Description',
    audioUrl: 'https://example.com/audio.mp3',
    publishDate: DateTime(2026, 1, 1),
    duration: 300,
  );

  setUp(() {
    service = AudioPlayerService.instance;
    mockHandler = MockMyStreamAudioHandler();
    service.setHandler(mockHandler);
  });

  group('AudioPlayerService Unit Tests', () {
    test('properties reflect handler values', () {
      mockHandler.simulatePosition(const Duration(seconds: 45));
      mockHandler.simulateDuration(const Duration(seconds: 300));
      mockHandler.simulateState(true, ProcessingState.ready);

      expect(service.isPlaying, isTrue);
      expect(service.position, const Duration(seconds: 45));
      expect(service.duration, const Duration(seconds: 300));
      expect(service.processingState, ProcessingState.ready);
      expect(service.speed, 1.0);
    });

    test('playEpisode configures mediaItem, loads source and plays', () async {
      await service.playEpisode(testEpisode, startPosition: const Duration(seconds: 15));

      expect(service.currentEpisode, equals(testEpisode));
      expect(mockHandler.loadSourceCalled, isTrue);
      expect(mockHandler.lastLoadedUrl, 'https://example.com/audio.mp3');
      expect(mockHandler.lastStartPosition, const Duration(seconds: 15));
      expect(mockHandler.playCalled, isTrue);
      expect(mockHandler.mediaItem.value?.title, 'Test Episode');
    });

    test('togglePlayPause pauses when playing', () async {
      mockHandler.simulateState(true, ProcessingState.ready);
      await service.togglePlayPause();
      expect(mockHandler.pauseCalled, isTrue);
    });

    test('togglePlayPause plays when paused', () async {
      mockHandler.simulateState(false, ProcessingState.ready);
      await service.togglePlayPause();
      expect(mockHandler.playCalled, isTrue);
    });

    test('togglePlayPause restarts and plays when completed', () async {
      mockHandler.simulateState(false, ProcessingState.completed);
      await service.togglePlayPause();
      expect(mockHandler.lastSeekPosition, Duration.zero);
      expect(mockHandler.playCalled, isTrue);
    });

    test('skipForward advances position bounded by duration', () async {
      mockHandler.simulatePosition(const Duration(seconds: 10));
      mockHandler.simulateDuration(const Duration(seconds: 60));

      await service.skipForward();
      expect(mockHandler.lastSeekPosition, const Duration(seconds: 10) + AppDurations.skipForward);

      // Near the end: clamp to duration
      mockHandler.simulatePosition(const Duration(seconds: 55));
      await service.skipForward();
      expect(mockHandler.lastSeekPosition, const Duration(seconds: 60));
    });

    test('skipBackward rewinds position bounded by zero', () async {
      mockHandler.simulatePosition(const Duration(seconds: 40));
      await service.skipBackward();
      expect(mockHandler.lastSeekPosition, const Duration(seconds: 40) - AppDurations.skipBackward);

      // Near zero: clamp to Duration.zero
      mockHandler.simulatePosition(const Duration(seconds: 5));
      await service.skipBackward();
      expect(mockHandler.lastSeekPosition, Duration.zero);
    });

    test('stop stops handler and clears currentEpisode', () async {
      await service.playEpisode(testEpisode);
      expect(service.currentEpisode, isNotNull);

      await service.stop();
      expect(mockHandler.stopCalled, isTrue);
      expect(service.currentEpisode, isNull);
    });

    test('setSpeed forwards speed to handler', () async {
      await service.setSpeed(1.5);
      expect(mockHandler.speed, 1.5);
    });
  });
}

import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../utils/logger.dart';

/// An [AudioHandler] that uses [just_audio] to play audio.
/// This class bridges the Flutter app with the OS media notification and
/// lock-screen controls.
class MyStreamAudioHandler extends BaseAudioHandler {
  final AudioPlayer player = AudioPlayer(
    handleInterruptions: false,
  );

  bool _playInterrupted = false;
  Timer? _duckTimer;

  MyStreamAudioHandler() {
    logger.d('MyStreamAudioHandler constructor called');
    _init();
  }

  Future<void> _init() async {
    try {
      logger.d('MyStreamAudioHandler._init() starting');
      // Configure audio session for speech/podcast playback with ducking
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
              await player.setVolume(0.2);
              _duckTimer = Timer(const Duration(seconds: 4), () {
                if (player.volume < 1.0) {
                  player.setVolume(1.0);
                }
              });
              break;
            case AudioInterruptionType.pause:
              if (player.playing) {
                logger.d('Player is playing, pausing due to interruption');
                _playInterrupted = true;
                await player.pause();
              }
              break;
            case AudioInterruptionType.unknown:
              if (player.playing) {
                logger.d('Player is playing, pausing due to focus loss');
                _playInterrupted = false;
                await player.pause();
              }
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _duckTimer?.cancel();
              await player.setVolume(1.0);
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
        logger.d('Audio becoming noisy (headphones unplugged), pausing playback');
        await pause();
      });

      // Broadcast playback state changes to the OS without closing the stream on errors
      player.playbackEventStream.listen(
        (event) {
          playbackState.add(_transformEvent(event));
        },
        onError: (Object e, StackTrace st) {
          logger.e('Error on playbackEventStream', error: e, stackTrace: st);
        },
      );
      logger.d('PlaybackState listener established');

      // Handle completion
      player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          stop();
        }
      });
      logger.d('MyStreamAudioHandler._init() completed');
    } catch (e) {
      logger.e('ERROR in MyStreamAudioHandler._init()', error: e);
    }
  }

  @override
  Future<void> play() async {
    _playInterrupted = false;
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
    } catch (e) {
      logger.w('Failed to activate AudioSession: $e');
    }
    return player.play();
  }

  @override
  Future<void> pause() {
    _playInterrupted = false;
    return player.pause();
  }

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    _playInterrupted = false;
    _duckTimer?.cancel();
    await player.stop();
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e) {
      logger.w('Failed to deactivate AudioSession: $e');
    }
    return super.stop();
  }

  @override
  Future<void> setSpeed(double speed) => player.setSpeed(speed);

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      _duckTimer?.cancel();
      await player.dispose();
    }
  }

  /// Transforms a just_audio event into an audio_service PlaybackState.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (player.playing) MediaControl.pause else MediaControl.play,
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
      }[player.processingState] ?? AudioProcessingState.idle,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    );
  }
}

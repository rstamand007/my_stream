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

  MyStreamAudioHandler() {
    logger.d('MyStreamAudioHandler constructor called');
    _init();
  }

  Future<void> _init() async {
    try {
      logger.d('MyStreamAudioHandler._init() starting');
      // Configure audio session for speech/podcast playback
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      logger.d('AudioSession configured for speech');

      // Listen to audio focus and system interruptions manually
      session.interruptionEventStream.listen((event) async {
        logger.d('Audio session interruption event: begin=${event.begin}, type=${event.type}');
        if (event.begin) {
          // Interruption began (e.g. phone call, SMS notification, navigation)
          switch (event.type) {
            case AudioInterruptionType.duck:
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              if (player.playing) {
                logger.d('Player is playing, pausing due to interruption');
                _playInterrupted = true;
                await player.pause();
              }
              break;
          }
        } else {
          // Interruption ended (transient focus regained)
          switch (event.type) {
            case AudioInterruptionType.duck:
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              if (_playInterrupted) {
                logger.d('Resuming playback after interruption ended');
                _playInterrupted = false;
                await play();
              }
              break;
          }
        }
      });

      // Handle headphone unplugged (Becoming noisy)
      session.becomingNoisyEventStream.listen((_) async {
        logger.d('Audio becoming noisy (headphones unplugged), pausing playback');
        await pause();
      });

      // Broadcast playback state changes to the OS
      player.playbackEventStream.map(_transformEvent).pipe(playbackState);
      logger.d('PlaybackState pipe established');

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
  Future<void> play() {
    _playInterrupted = false;
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
    await player.stop();
    return super.stop();
  }

  @override
  Future<void> setSpeed(double speed) => player.setSpeed(speed);

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
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
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    );
  }
}

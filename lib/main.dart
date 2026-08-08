import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_stream/l10n/app_localizations.dart';
import 'providers/podcast_provider.dart';
import 'providers/player_provider.dart';
import 'providers/download_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'models/episode.dart';
import 'screens/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/database_service.dart';
import 'package:audio_service/audio_service.dart';
import 'services/audio_handler.dart';
import 'services/audio_player_service.dart';
import 'utils/logger.dart';

/// Top-level function required by audio_service to initialize the handler
/// in a separate background isolate. Background isolates cannot access
/// closures inside main().
MyStreamAudioHandler _initAudioHandler() {
  return MyStreamAudioHandler();
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Hive
    await Hive.initFlutter();

    // Initialize Database Service
    await DatabaseService.instance.init();

    // Bootstrap audio_service
    final audioHandler = await AudioService.init<MyStreamAudioHandler>(
      builder: _initAudioHandler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.mystream.my_stream.audio',
        androidNotificationChannelName: 'MyStream Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );

    // Give AudioPlayerService a reference to the handler.
    AudioPlayerService.instance.setHandler(audioHandler);

    runApp(const MyStreamApp());
  } catch (e, stack) {
    logger.e('CRITICAL ERROR DURING STARTUP', error: e, stackTrace: stack);
    runApp(const MyStreamApp());
  }
}

class MyStreamApp extends StatelessWidget {
  const MyStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            logger.d('Initializing PodcastProvider');
            return PodcastProvider()..init();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            logger.d('Initializing PlayerProvider');
            return PlayerProvider()..init();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            logger.d('Initializing DownloadProvider');
            return DownloadProvider()..init();
          },
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Wire up autoplay logic
          final playerProvider = context.read<PlayerProvider>();
          final downloadProvider = context.read<DownloadProvider>();

          playerProvider.onEpisodeEnded = () async {
            final currentEpisode = playerProvider.currentEpisode;
            if (currentEpisode == null) return;

            final downloads = downloadProvider.downloadedEpisodes;
            final currentIndex = downloads.indexWhere(
              (e) => e.id == currentEpisode.id,
            );

            Episode? nextEpisode;
            if (downloadProvider.isAutoplayEnabled &&
                currentIndex != -1 &&
                currentIndex + 1 < downloads.length) {
              nextEpisode = downloads[currentIndex + 1];
            }

            if (nextEpisode != null) {
              await playerProvider.playEpisode(nextEpisode);
            } else {
              await playerProvider.stop();
            }

            // If it was a downloaded episode, delete it from storage and the list
            if (currentIndex != -1) {
              await downloadProvider.deleteDownload(currentEpisode);
            }
          };

          return Consumer2<LocaleProvider, ThemeProvider>(
            builder: (context, localeProvider, themeProvider, child) {
              return MaterialApp(
                title: 'MyStream',
                debugShowCheckedModeBanner: false,
                locale: localeProvider.locale,
                themeMode: themeProvider.themeMode,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('en'), Locale('fr')],
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                home: const SplashScreen(),
              );
            },
          );
        },
      ),
    );
  }
}

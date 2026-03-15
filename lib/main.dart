import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_stream/l10n/app_localizations.dart';
import 'providers/podcast_provider.dart';
import 'providers/player_provider.dart';
import 'providers/download_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/database_service.dart';
import 'package:audio_service/audio_service.dart';
import 'services/audio_handler.dart';
import 'services/audio_player_service.dart';

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
    print('DEBUG: CRITICAL ERROR DURING STARTUP: $e');
    print(stack);
    runApp(const MyStreamApp());
  }
}

class MyStreamApp extends StatelessWidget {
  const MyStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          print('DEBUG: Initializing PodcastProvider');
          return PodcastProvider()..init();
        }),
        ChangeNotifierProvider(create: (_) {
          print('DEBUG: Initializing PlayerProvider');
          return PlayerProvider()..init();
        }),
        ChangeNotifierProvider(create: (_) {
          print('DEBUG: Initializing DownloadProvider');
          return DownloadProvider()..init();
        }),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
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
            // Light Theme
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                surface: Colors.white,
              ),
              scaffoldBackgroundColor: Colors.grey[50],
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
              ),
              textTheme: const TextTheme(
                headlineLarge: TextStyle(
                  color: Colors.black87,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                headlineMedium: TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
                bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            // Dark Theme
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.dark(
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                surface: AppColors.surface,
              ),
              scaffoldBackgroundColor: AppColors.background,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.background,
                elevation: 0,
              ),
              cardTheme: const CardThemeData(
                color: AppColors.surface,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              textTheme: const TextTheme(
                headlineLarge: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                headlineMedium: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                bodyLarge: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                bodyMedium: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

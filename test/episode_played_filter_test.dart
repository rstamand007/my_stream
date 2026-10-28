import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_stream/models/podcast.dart';
import 'package:my_stream/models/episode.dart';
import 'package:my_stream/providers/podcast_provider.dart';
import 'package:my_stream/providers/player_provider.dart';
import 'package:my_stream/providers/download_provider.dart';
import 'package:my_stream/screens/podcast_detail_screen.dart';
import 'package:my_stream/widgets/episode_tile.dart';
import 'package:my_stream/l10n/app_localizations.dart';

class MockPodcastProvider extends ChangeNotifier implements PodcastProvider {
  final List<Episode> _episodes = [];
  final List<Podcast> _subscribedPodcasts = [];
  bool _isLoading = false;

  void setEpisodes(List<Episode> episodes) {
    _episodes.clear();
    _episodes.addAll(episodes);
    notifyListeners();
  }

  @override
  bool get isLoading => _isLoading;

  @override
  List<Podcast> get subscribedPodcasts => _subscribedPodcasts;

  @override
  bool isPodcastSubscribed(String podcastId) => true;

  @override
  List<Episode> getEpisodes(String podcastId) => List.unmodifiable(_episodes);

  @override
  Future<void> loadEpisodes(String podcastId) async {}

  @override
  Future<void> fetchEpisodes(String podcastId, String feedUrl) async {}

  @override
  Future<void> refreshEpisodes(String podcastId, String feedUrl) async {}

  @override
  Future<void> setEpisodePlayedStatus(String episodeId, bool isPlayed) async {
    final index = _episodes.indexWhere((e) => e.id == episodeId);
    if (index != -1) {
      _episodes[index] = _episodes[index].copyWith(isPlayed: isPlayed);
      notifyListeners();
    }
  }

  @override
  void updateInMemoryPlayedStatus(String episodeId, bool isPlayed) {
    setEpisodePlayedStatus(episodeId, isPlayed);
  }

  @override
  Future<void> setAllEpisodesPlayedStatus(String podcastId, bool isPlayed) async {
    for (int i = 0; i < _episodes.length; i++) {
      _episodes[i] = _episodes[i].copyWith(isPlayed: isPlayed);
    }
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPlayerProvider extends ChangeNotifier implements PlayerProvider {
  @override
  Episode? get currentEpisode => null;

  @override
  bool get isPlaying => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDownloadProvider extends ChangeNotifier implements DownloadProvider {
  @override
  bool isDownloaded(String episodeId) => false;

  @override
  bool isDownloading(String episodeId) => false;

  @override
  double getProgress(String episodeId) => 0.0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Podcast testPodcast;
  late MockPodcastProvider mockPodcastProvider;
  late MockPlayerProvider mockPlayerProvider;
  late MockDownloadProvider mockDownloadProvider;

  final episode1 = Episode(
    id: 'ep-1',
    podcastId: 'pod-1',
    title: 'Episode One',
    description: 'First episode',
    audioUrl: 'https://example.com/ep1.mp3',
    duration: 1200,
    publishDate: DateTime(2026, 3, 1),
    isPlayed: false,
  );

  final episode2 = Episode(
    id: 'ep-2',
    podcastId: 'pod-1',
    title: 'Episode Two',
    description: 'Second episode',
    audioUrl: 'https://example.com/ep2.mp3',
    duration: 1800,
    publishDate: DateTime(2026, 3, 2),
    isPlayed: true,
  );

  setUp(() {
    testPodcast = Podcast(
      id: 'pod-1',
      title: 'Tech Weekly',
      author: 'Jane Doe',
      description: 'Weekly tech podcast',
      artworkUrl: '',
      feedUrl: 'https://example.com/feed.xml',
    );
    mockPodcastProvider = MockPodcastProvider();
    mockPlayerProvider = MockPlayerProvider();
    mockDownloadProvider = MockDownloadProvider();
  });

  Widget createWidgetUnderTest({Locale locale = const Locale('en')}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PodcastProvider>.value(value: mockPodcastProvider),
        ChangeNotifierProvider<PlayerProvider>.value(value: mockPlayerProvider),
        ChangeNotifierProvider<DownloadProvider>.value(value: mockDownloadProvider),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('fr')],
        home: PodcastDetailScreen(podcast: testPodcast),
      ),
    );
  }

  testWidgets('EpisodeTile displays played badge and menu to toggle played status', (
    WidgetTester tester,
  ) async {
    bool toggledStatus = false;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PlayerProvider>.value(value: mockPlayerProvider),
          ChangeNotifierProvider<DownloadProvider>.value(value: mockDownloadProvider),
          ChangeNotifierProvider<PodcastProvider>.value(value: mockPodcastProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('fr')],
          home: Scaffold(
            body: EpisodeTile(
              episode: episode2,
              onTogglePlayed: (val) {
                toggledStatus = val;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Played text and check icon should be shown for played episode
    expect(find.textContaining('Played'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // More options menu
    final moreButton = find.byIcon(Icons.more_vert_rounded);
    expect(moreButton, findsOneWidget);

    await tester.tap(moreButton);
    await tester.pump(const Duration(milliseconds: 500));

    // Menu item to mark as unplayed
    final markUnplayedItem = find.text('Mark as unplayed');
    expect(markUnplayedItem, findsOneWidget);

    await tester.tap(markUnplayedItem, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));

    expect(toggledStatus, isFalse);
  });

  testWidgets('PodcastDetailScreen filters by unread episodes', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    mockPodcastProvider.setEpisodes([episode1, episode2]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 500));

    // By default, All chip is selected and both episodes are visible
    expect(find.text('Episode One'), findsOneWidget);
    expect(find.text('Episode Two'), findsOneWidget);

    final unreadChip = find.byKey(const ValueKey('filter_unread_chip'));
    expect(unreadChip, findsOneWidget);

    // Tap the Unread filter chip
    await tester.tap(unreadChip);
    await tester.pump(const Duration(milliseconds: 500));

    // Now only unread episode should be displayed
    expect(find.text('Episode One'), findsOneWidget);
    expect(find.text('Episode Two'), findsNothing);

    // Tap All chip to switch back
    final allChip = find.byKey(const ValueKey('filter_all_chip'));
    await tester.tap(allChip);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Episode One'), findsOneWidget);
    expect(find.text('Episode Two'), findsOneWidget);
  });

  testWidgets('PodcastDetailScreen shows empty state when all episodes are played and unread filter is active', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    mockPodcastProvider.setEpisodes([episode2]); // Only 1 played episode

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 500));

    final unreadChip = find.byKey(const ValueKey('filter_unread_chip'));
    await tester.tap(unreadChip);
    await tester.pump(const Duration(milliseconds: 500));

    // Should display empty state
    expect(find.text('All episodes played'), findsOneWidget);

    // Button to show all episodes
    final showAllBtn = find.text('Show all episodes');
    expect(showAllBtn, findsOneWidget);

    await tester.tap(showAllBtn);
    await tester.pump(const Duration(milliseconds: 500));

    // Switched back to all episodes
    expect(find.text('Episode Two'), findsOneWidget);
  });

  testWidgets('French localization works for unread filter and played status', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    mockPodcastProvider.setEpisodes([episode1, episode2]);

    await tester.pumpWidget(createWidgetUnderTest(locale: const Locale('fr')));
    await tester.pump(const Duration(milliseconds: 500));

    // Chips should display French labels
    expect(find.textContaining('Tous'), findsOneWidget);
    expect(find.textContaining('Non lu'), findsOneWidget);
    expect(find.textContaining('Lu'), findsOneWidget);
  });
}

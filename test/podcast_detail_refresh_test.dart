import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_stream/screens/podcast_detail_screen.dart';
import 'package:my_stream/providers/podcast_provider.dart';
import 'package:my_stream/models/podcast.dart';
import 'package:my_stream/models/episode.dart';
import 'package:my_stream/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MockPodcastProvider extends ChangeNotifier implements PodcastProvider {
  bool _isLoading = false;
  final List<Podcast> _subscribedPodcasts = [];
  bool _refreshCalled = false;

  bool get refreshCalled => _refreshCalled;

  @override
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  List<Podcast> get subscribedPodcasts => _subscribedPodcasts;

  @override
  bool isPodcastSubscribed(String podcastId) =>
      _subscribedPodcasts.any((p) => p.id == podcastId);

  @override
  Future<void> refreshEpisodes(String podcastId, String feedUrl) async {
    _refreshCalled = true;
    _isLoading = true;
    notifyListeners();
    // Simulate network delay if needed, but for tests we can just leave it loading
  }

  @override
  List<Episode> getEpisodes(String podcastId) => [];

  @override
  Future<void> loadEpisodes(String podcastId) async {}

  @override
  Future<void> fetchEpisodes(String podcastId, String feedUrl) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Podcast testPodcast;
  late MockPodcastProvider mockProvider;

  setUp(() {
    testPodcast = Podcast(
      id: '1',
      title: 'Test Podcast',
      author: 'Test Author',
      description: 'Test Description',
      artworkUrl: '',
      feedUrl: 'https://example.com/feed.xml',
      lastUpdatedAt: DateTime(2026, 2, 27, 10, 0),
    );
    mockProvider = MockPodcastProvider();
    mockProvider.subscribedPodcasts.add(testPodcast);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr')],
      home: ChangeNotifierProvider<PodcastProvider>.value(
        value: mockProvider,
        child: PodcastDetailScreen(podcast: testPodcast),
      ),
    );
  }

  testWidgets('Refresh button exists and triggers refresh', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final refreshButton = find.byIcon(Icons.refresh);
    expect(refreshButton, findsOneWidget);

    await tester.tap(refreshButton);
    expect(mockProvider.refreshCalled, isTrue);
  });

  testWidgets('Last updated field is displayed when available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // The DateFormat.yMMMd().add_Hm() for Feb 27, 2026 10:00
    // "Feb 27, 2026 10:00" (English)
    expect(find.textContaining('Last updated:'), findsOneWidget);
    expect(find.textContaining('Feb 27, 2026'), findsOneWidget);
  });

  testWidgets('Loading indicator shows during refresh', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Initially no progress indicator
    expect(find.byType(LinearProgressIndicator), findsNothing);

    // Trigger loading state
    mockProvider.setLoading(true);
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Stop loading
    mockProvider.setLoading(false);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('Refresh button is disabled while loading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    mockProvider.setLoading(true);
    await tester.pump();

    final refreshButton = tester.widget<IconButton>(find.byIcon(Icons.refresh));
    expect(refreshButton.onPressed, isNull);
  });
}

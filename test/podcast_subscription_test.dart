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
  bool _isSubscribed = false;

  @override
  bool isPodcastSubscribed(String podcastId) => _isSubscribed;

  @override
  Future<void> subscribeToPodcast(Podcast podcast) async {
    _isSubscribed = true;
    notifyListeners();
  }

  @override
  Future<void> unsubscribeFromPodcast(String podcastId) async {
    _isSubscribed = false;
    notifyListeners();
  }

  @override
  List<Episode> getEpisodes(String podcastId) => [];

  @override
  bool get isLoading => false;

  @override
  Future<void> fetchEpisodes(String podcastId, String feedUrl) async {}

  @override
  Future<void> loadEpisodes(String podcastId) async {}

  // Other overrides required by PodcastProvider interface
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
      feedUrl: '',
    );
    mockProvider = MockPodcastProvider();
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

  testWidgets('Subscription button label toggles and matches state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 500));

    // Initially not subscribed - expect add icon
    final addButton = find.byIcon(Icons.add_circle_outline_rounded);
    expect(addButton, findsOneWidget);

    // Ensure visible and tap the button
    await tester.ensureVisible(addButton);
    await tester.tap(
      find.ancestor(of: addButton, matching: find.byType(ElevatedButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Should now be subscribed - expect check icon
    final checkButton = find.byIcon(Icons.check_rounded);
    expect(checkButton, findsOneWidget);

    // Ensure visible and tap the button again to unsubscribe
    await tester.ensureVisible(checkButton);
    await tester.tap(
      find.ancestor(of: checkButton, matching: find.byType(ElevatedButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Should be unsubscribed again - expect add icon
    expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:my_stream/models/podcast.dart';

void main() {
  group('Podcast Model Tests', () {
    final testDate = DateTime(2026, 2, 27, 13, 0);

    final podcast = Podcast(
      id: '1',
      title: 'Test Podcast',
      author: 'Test Author',
      description: 'Test Description',
      artworkUrl: 'https://example.com/artwork.jpg',
      feedUrl: 'https://example.com/feed.xml',
      isSubscribed: true,
      lastUpdatedAt: testDate,
    );

    test('Podcast.toMap includes lastUpdatedAt', () {
      final map = podcast.toMap();
      expect(map['lastUpdatedAt'], testDate.millisecondsSinceEpoch);
    });

    test('Podcast.fromMap handles lastUpdatedAt', () {
      final map = {
        'id': '1',
        'title': 'Test Podcast',
        'author': 'Test Author',
        'description': 'Test Description',
        'artworkUrl': 'https://example.com/artwork.jpg',
        'feedUrl': 'https://example.com/feed.xml',
        'isSubscribed': 1,
        'lastUpdatedAt': testDate.millisecondsSinceEpoch,
      };

      final fromMap = Podcast.fromMap(map);
      expect(fromMap.lastUpdatedAt, testDate);
    });

    test('Podcast.fromJson handles lastUpdatedAt', () {
      final json = {
        'collectionId': '1',
        'collectionName': 'Test Podcast',
        'artistName': 'Test Author',
        'description': 'Test Description',
        'artworkUrl100': 'https://example.com/artwork.jpg',
        'feedUrl': 'https://example.com/feed.xml',
        'lastUpdatedAt': testDate.toIso8601String(),
      };

      final fromJson = Podcast.fromJson(json);
      expect(fromJson.lastUpdatedAt, testDate);
    });

    test('Podcast.copyWith updates lastUpdatedAt', () {
      final newDate = DateTime(2026, 2, 27, 14, 0);
      final updated = podcast.copyWith(lastUpdatedAt: newDate);
      expect(updated.lastUpdatedAt, newDate);
      expect(updated.id, podcast.id);
    });

    test('Podcast handles null lastUpdatedAt', () {
      final nullDatePodcast = podcast.copyWith(lastUpdatedAt: null);
      expect(nullDatePodcast.lastUpdatedAt, isNull);

      final map = nullDatePodcast.toMap();
      expect(map['lastUpdatedAt'], isNull);

      final fromMap = Podcast.fromMap(map);
      expect(fromMap.lastUpdatedAt, isNull);
    });
  });
}

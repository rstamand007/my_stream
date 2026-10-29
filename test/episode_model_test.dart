import 'package:flutter_test/flutter_test.dart';
import 'package:my_stream/models/episode.dart';

void main() {
  group('Episode Model Tests', () {
    final pubDate = DateTime(2026, 3, 15, 10, 0);

    final episode = Episode(
      id: 'ep-1',
      podcastId: 'pod-1',
      title: 'Episode 1',
      description: 'First episode description',
      audioUrl: 'https://example.com/ep1.mp3',
      duration: 1800,
      publishDate: pubDate,
      isPlayed: false,
    );

    test('Episode defaults isPlayed to false', () {
      final defaultEpisode = Episode(
        id: 'ep-2',
        podcastId: 'pod-1',
        title: 'Episode 2',
        description: 'Desc',
        audioUrl: 'https://example.com/ep2.mp3',
        duration: 1200,
        publishDate: pubDate,
      );
      expect(defaultEpisode.isPlayed, isFalse);
    });

    test('Episode.toMap includes isPlayed', () {
      final mapUnplayed = episode.toMap();
      expect(mapUnplayed['isPlayed'], 0);

      final mapPlayed = episode.copyWith(isPlayed: true).toMap();
      expect(mapPlayed['isPlayed'], 1);
    });

    test('Episode.fromMap correctly parses isPlayed as 1 or true', () {
      final map1 = {
        'id': 'ep-1',
        'podcastId': 'pod-1',
        'title': 'Episode 1',
        'description': 'Desc',
        'audioUrl': 'https://example.com/ep1.mp3',
        'duration': 1800,
        'publishDate': pubDate.millisecondsSinceEpoch,
        'isDownloaded': 0,
        'isPlayed': 1,
      };
      expect(Episode.fromMap(map1).isPlayed, isTrue);

      final map2 = {
        'id': 'ep-1',
        'podcastId': 'pod-1',
        'title': 'Episode 1',
        'description': 'Desc',
        'audioUrl': 'https://example.com/ep1.mp3',
        'duration': 1800,
        'publishDate': pubDate.millisecondsSinceEpoch,
        'isDownloaded': 0,
        'isPlayed': 0,
      };
      expect(Episode.fromMap(map2).isPlayed, isFalse);
    });

    test('Episode.copyWith updates isPlayed without affecting other fields', () {
      final played = episode.copyWith(isPlayed: true);
      expect(played.isPlayed, isTrue);
      expect(played.id, episode.id);
      expect(played.title, episode.title);

      final unplayed = played.copyWith(isPlayed: false);
      expect(unplayed.isPlayed, isFalse);
    });
  });
}


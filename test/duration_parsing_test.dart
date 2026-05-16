import 'package:flutter_test/flutter_test.dart';
import 'package:my_stream/models/episode.dart';

void main() {
  group('Episode Duration Parsing', () {
    test('Parses HH:MM:SS', () {
      expect(Episode.parseDuration('01:02:03'), 3600 + 120 + 3);
    });

    test('Parses MM:SS', () {
      expect(Episode.parseDuration('05:30'), 300 + 30);
    });

    test('Parses raw seconds as string', () {
      expect(Episode.parseDuration('120'), 120);
    });

    test('Handles null', () {
      expect(Episode.parseDuration(null), 0);
    });

    test('Handles invalid format', () {
      expect(Episode.parseDuration('invalid'), 0);
    });
  });
}

// Extension to expose private method for testing if needed,
// but _parseDuration is static and I can make it public or test it via a public method.
// Actually, it's already used in Episode.fromRss.
// I'll update Episode to make it public if it's not.

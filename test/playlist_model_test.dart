import 'package:flutter_test/flutter_test.dart';
import 'package:my_stream/models/playlist.dart';

void main() {
  test('system playlist remains protected when copied', () {
    const playlist = Playlist(
      id: 'newest-subscribed-episodes',
      name: 'Newest subscribed episodes',
      episodeIds: ['episode-1'],
      isSystem: true,
    );

    final updated = playlist.copyWith(
      name: 'Renamed',
      episodeIds: ['episode-2'],
    );

    expect(updated.isSystem, isTrue);
    expect(updated.id, playlist.id);
    expect(updated.name, 'Renamed');
    expect(updated.episodeIds, ['episode-2']);
  });

  test('playlist keeps a playback position for each episode', () {
    const playlist = Playlist(
      id: 'playlist-1',
      name: 'Favorites',
      episodeIds: ['episode-1'],
      playbackPositions: {'episode-1': 125},
    );

    final updated = playlist.copyWith(playbackPositions: {'episode-1': 180});

    expect(updated.playbackPositions['episode-1'], 180);
  });
}

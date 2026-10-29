import 'package:flutter_test/flutter_test.dart';
import 'package:my_stream/models/episode.dart';
import 'package:my_stream/models/playlist.dart';
import 'package:my_stream/models/podcast.dart';
import 'package:my_stream/providers/playlist_provider.dart';
import 'package:my_stream/services/database_service.dart';

class FakeDatabaseService implements DatabaseService {
  final List<Podcast> podcasts = [];
  final Map<String, List<Episode>> episodesByPodcast = {};
  final Map<String, Playlist> playlists = {};

  @override
  Future<List<Podcast>> getSubscribedPodcasts() async {
    return podcasts.where((p) => p.isSubscribed).toList();
  }

  @override
  Future<List<Episode>> getEpisodesByPodcast(String podcastId) async {
    final list = episodesByPodcast[podcastId] ?? [];
    return List.of(list)..sort((a, b) => b.publishDate.compareTo(a.publishDate));
  }

  @override
  Future<List<Episode>> getAllEpisodes() async {
    final all = <Episode>[];
    for (final list in episodesByPodcast.values) {
      all.addAll(list);
    }
    all.sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return all;
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    return playlists.values.toList();
  }

  @override
  Future<void> insertPlaylist(Playlist playlist) async {
    playlists[playlist.id] = playlist;
  }

  @override
  Future<void> updatePlaylist(Playlist playlist) async {
    playlists[playlist.id] = playlist;
  }

  @override
  Future<void> deletePlaylist(String id) async {
    playlists.remove(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeDatabaseService fakeDb;
  late PlaylistProvider provider;

  final podcast1 = Podcast(
    id: 'pod-1',
    title: 'Podcast One',
    author: 'Author 1',
    description: 'Desc 1',
    artworkUrl: '',
    feedUrl: 'https://example.com/feed1.xml',
    isSubscribed: true,
  );

  final podcast2 = Podcast(
    id: 'pod-2',
    title: 'Podcast Two',
    author: 'Author 2',
    description: 'Desc 2',
    artworkUrl: '',
    feedUrl: 'https://example.com/feed2.xml',
    isSubscribed: true,
  );

  final podcast3 = Podcast(
    id: 'pod-3',
    title: 'Podcast Three',
    author: 'Author 3',
    description: 'Desc 3',
    artworkUrl: '',
    feedUrl: 'https://example.com/feed3.xml',
    isSubscribed: true,
  );

  // Podcast 1: newest ep-1 is played, older ep-2 is unplayed
  final ep1 = Episode(
    id: 'ep-1',
    podcastId: 'pod-1',
    title: 'Ep 1 (Newest, Played)',
    description: 'Desc',
    audioUrl: 'https://example.com/ep1.mp3',
    duration: 1000,
    publishDate: DateTime(2026, 3, 10),
    isPlayed: true,
  );

  final ep2 = Episode(
    id: 'ep-2',
    podcastId: 'pod-1',
    title: 'Ep 2 (Older, Unplayed)',
    description: 'Desc',
    audioUrl: 'https://example.com/ep2.mp3',
    duration: 1000,
    publishDate: DateTime(2026, 3, 5),
    isPlayed: false,
  );

  // Podcast 2: newest ep-3 is unplayed, older ep-4 is unplayed
  final ep3 = Episode(
    id: 'ep-3',
    podcastId: 'pod-2',
    title: 'Ep 3 (Newest, Unplayed)',
    description: 'Desc',
    audioUrl: 'https://example.com/ep3.mp3',
    duration: 1000,
    publishDate: DateTime(2026, 3, 12),
    isPlayed: false,
  );

  final ep4 = Episode(
    id: 'ep-4',
    podcastId: 'pod-2',
    title: 'Ep 4 (Older, Unplayed)',
    description: 'Desc',
    audioUrl: 'https://example.com/ep4.mp3',
    duration: 1000,
    publishDate: DateTime(2026, 3, 4),
    isPlayed: false,
  );

  // Podcast 3: only has played episodes
  final ep5 = Episode(
    id: 'ep-5',
    podcastId: 'pod-3',
    title: 'Ep 5 (Only, Played)',
    description: 'Desc',
    audioUrl: 'https://example.com/ep5.mp3',
    duration: 1000,
    publishDate: DateTime(2026, 3, 1),
    isPlayed: true,
  );

  setUp(() {
    fakeDb = FakeDatabaseService();
    fakeDb.podcasts.addAll([podcast1, podcast2, podcast3]);
    fakeDb.episodesByPodcast['pod-1'] = [ep1, ep2];
    fakeDb.episodesByPodcast['pod-2'] = [ep3, ep4];
    fakeDb.episodesByPodcast['pod-3'] = [ep5];

    provider = PlaylistProvider(databaseService: fakeDb);
  });

  test('Newest subscribed episodes playlist only includes unplayed episodes', () async {
    await provider.load();

    final generatedPlaylist = provider.playlists.firstWhere(
      (p) => p.id == PlaylistProvider.generatedPlaylistId,
    );

    // Podcast 1: ep-1 is played, so newest unplayed should be ep-2
    // Podcast 2: ep-3 is unplayed, so newest unplayed should be ep-3
    // Podcast 3: ep-5 is played, so no unplayed episode should be included
    expect(generatedPlaylist.episodeIds, contains('ep-2'));
    expect(generatedPlaylist.episodeIds, contains('ep-3'));
    expect(generatedPlaylist.episodeIds, isNot(contains('ep-1')));
    expect(generatedPlaylist.episodeIds, isNot(contains('ep-5')));
    expect(generatedPlaylist.episodeIds.length, 2);

    final episodes = provider.episodesFor(generatedPlaylist);
    expect(episodes.map((e) => e.id), containsAll(['ep-2', 'ep-3']));
    expect(episodes.every((e) => !e.isPlayed), isTrue);
  });

  test('Updating episode to played removes it and selects next unplayed episode', () async {
    await provider.load();

    // Mark ep-3 as played in DB
    final updatedEp3 = ep3.copyWith(isPlayed: true);
    fakeDb.episodesByPodcast['pod-2'] = [updatedEp3, ep4];

    await provider.updateEpisodePlayedStatus('ep-3', true);

    final generatedPlaylist = provider.playlists.firstWhere(
      (p) => p.id == PlaylistProvider.generatedPlaylistId,
    );

    // ep-3 should be replaced by ep-4 (now the newest unplayed episode for pod-2)
    expect(generatedPlaylist.episodeIds, isNot(contains('ep-3')));
    expect(generatedPlaylist.episodeIds, contains('ep-4'));
    expect(generatedPlaylist.episodeIds, contains('ep-2'));
    expect(generatedPlaylist.episodeIds.length, 2);
  });

  test('When all episodes of a podcast become played, it is removed from the playlist', () async {
    await provider.load();

    // Mark ep-2 as played in DB
    final updatedEp2 = ep2.copyWith(isPlayed: true);
    fakeDb.episodesByPodcast['pod-1'] = [ep1, updatedEp2];

    await provider.updateEpisodePlayedStatus('ep-2', true);

    final generatedPlaylist = provider.playlists.firstWhere(
      (p) => p.id == PlaylistProvider.generatedPlaylistId,
    );

    // Podcast 1 has no more unplayed episodes
    expect(generatedPlaylist.episodeIds, isNot(contains('ep-2')));
    expect(generatedPlaylist.episodeIds, isNot(contains('ep-1')));
    expect(generatedPlaylist.episodeIds, contains('ep-3'));
    expect(generatedPlaylist.episodeIds.length, 1);
  });

  test('episodesFor on generated playlist filters out any played episode', () {
    const playlist = Playlist(
      id: PlaylistProvider.generatedPlaylistId,
      name: PlaylistProvider.generatedPlaylistName,
      episodeIds: ['ep-1', 'ep-2', 'ep-3'],
      isSystem: true,
    );

    // Even if ep-1 is in episodeIds, episodesFor filters it out
    final episodes = provider.episodesFor(playlist);
    expect(episodes.map((e) => e.id), isNot(contains('ep-1')));
  });
}

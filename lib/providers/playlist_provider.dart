import 'package:flutter/foundation.dart';
import '../models/episode.dart';
import '../models/playlist.dart';
import '../services/database_service.dart';

class PlaylistProvider with ChangeNotifier {
  static const generatedPlaylistId = 'newest-subscribed-episodes';
  static const generatedPlaylistName = 'Newest subscribed episodes';

  final DatabaseService _db = DatabaseService.instance;
  List<Playlist> _playlists = [];
  List<Episode> _allEpisodes = [];
  bool _isLoading = false;

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<Episode> get allEpisodes => List.unmodifiable(_allEpisodes);
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await load();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _allEpisodes = await _db.getAllEpisodes();
    _playlists = await _db.getPlaylists();
    await _refreshGeneratedPlaylist();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshGeneratedPlaylist() async {
    await _refreshGeneratedPlaylist();
    notifyListeners();
  }

  Future<void> createPlaylist(String name, List<String> episodeIds) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmedName,
      episodeIds: List.of(episodeIds),
    );
    await _db.insertPlaylist(playlist);
    _playlists = [..._playlists, playlist];
    notifyListeners();
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    if (playlist.isSystem) return;
    final updated = playlist.copyWith(
      name: playlist.name.trim(),
      episodeIds: List.of(playlist.episodeIds),
    );
    if (updated.name.isEmpty) return;
    await _db.updatePlaylist(updated);
    _playlists = _playlists
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    notifyListeners();
  }

  Future<void> reorderPlaylist(
    Playlist playlist,
    List<String> episodeIds,
  ) async {
    final updated = playlist.copyWith(episodeIds: episodeIds);
    await _db.updatePlaylist(updated);
    _playlists = _playlists
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    notifyListeners();
  }

  int playbackPositionFor(Playlist playlist, Episode episode) {
    return playlist.playbackPositions[episode.id] ??
        episode.playbackPosition ??
        0;
  }

  Future<void> updatePlaybackPosition(String episodeId, int position) async {
    final updates = <Playlist>[];
    for (final playlist in _playlists) {
      if (!playlist.episodeIds.contains(episodeId)) continue;
      final updated = playlist.copyWith(
        playbackPositions: {...playlist.playbackPositions, episodeId: position},
      );
      updates.add(updated);
    }
    if (updates.isEmpty) return;
    for (final playlist in updates) {
      await _db.updatePlaylist(playlist);
    }
    final updatesById = {for (final playlist in updates) playlist.id: playlist};
    _playlists = _playlists
        .map((playlist) => updatesById[playlist.id] ?? playlist)
        .toList();
    notifyListeners();
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    if (playlist.isSystem) return;
    await _db.deletePlaylist(playlist.id);
    _playlists = _playlists.where((item) => item.id != playlist.id).toList();
    notifyListeners();
  }

  List<Episode> episodesFor(Playlist playlist) {
    final byId = {for (final episode in _allEpisodes) episode.id: episode};
    return playlist.episodeIds
        .map((id) => byId[id])
        .whereType<Episode>()
        .toList();
  }

  Future<void> _refreshGeneratedPlaylist() async {
    final existing = _playlists
        .where((playlist) => playlist.id == generatedPlaylistId)
        .firstOrNull;
    final subscribedPodcasts = await _db.getSubscribedPodcasts();
    final newestEpisodeIds = <String>[];
    for (final podcast in subscribedPodcasts) {
      final episodes = await _db.getEpisodesByPodcast(podcast.id);
      if (episodes.isNotEmpty) newestEpisodeIds.add(episodes.first.id);
    }

    final orderedEpisodeIds = [
      ...?existing?.episodeIds.where(newestEpisodeIds.contains),
      ...newestEpisodeIds.where(
        (episodeId) => !(existing?.episodeIds.contains(episodeId) ?? false),
      ),
    ];

    final generated = Playlist(
      id: generatedPlaylistId,
      name: generatedPlaylistName,
      episodeIds: orderedEpisodeIds,
      isSystem: true,
    );
    await _db.insertPlaylist(generated);
    _playlists = [
      ..._playlists.where((playlist) => playlist.id != generatedPlaylistId),
      generated,
    ];
  }
}

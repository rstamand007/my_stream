import 'package:flutter/material.dart';
import 'package:podcast_search/podcast_search.dart' as ps;
import '../models/podcast.dart';
import '../models/episode.dart';
import '../services/database_service.dart';
import '../services/podcast_api_service.dart';

class PodcastProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final PodcastApiService _api = PodcastApiService();

  List<Podcast> _subscribedPodcasts = [];
  List<Podcast> _searchResults = [];
  final Map<String, List<Episode>> _podcastEpisodes = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Podcast> get subscribedPodcasts => _subscribedPodcasts;
  List<Podcast> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Episode> getEpisodes(String podcastId) {
    return _podcastEpisodes[podcastId] ?? [];
  }

  // Initialize - load subscribed podcasts
  Future<void> init() async {
    await loadSubscribedPodcasts();
  }

  // Load subscribed podcasts from database
  Future<void> loadSubscribedPodcasts() async {
    try {
      _isLoading = true;
      notifyListeners();

      _subscribedPodcasts = await _db.getSubscribedPodcasts();

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load podcasts: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search podcasts
  Future<void> searchPodcasts(
    String query, {
    ps.Country? country,
    ps.Attribute? attribute,
    String? language,
  }) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      _searchResults = await _api.searchPodcasts(
        query,
        country: country,
        attribute: attribute,
        language: language,
      );

      // Check which podcasts are already subscribed
      for (var i = 0; i < _searchResults.length; i++) {
        final existing = await _db.getPodcast(_searchResults[i].id);
        if (existing != null) {
          _searchResults[i] = existing;
        }
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Search failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Subscribe to podcast
  Future<void> subscribeToPodcast(Podcast podcast) async {
    try {
      final subscribedPodcast = podcast.copyWith(isSubscribed: true);
      await _db.insertPodcast(subscribedPodcast);

      // Fetch episodes
      await fetchEpisodes(podcast.id, podcast.feedUrl);

      await loadSubscribedPodcasts();
    } catch (e) {
      _error = 'Failed to subscribe: $e';
      notifyListeners();
    }
  }

  // Unsubscribe from podcast
  Future<void> unsubscribeFromPodcast(String podcastId) async {
    try {
      await _db.deletePodcast(podcastId);
      _podcastEpisodes.remove(podcastId);
      await loadSubscribedPodcasts();
    } catch (e) {
      _error = 'Failed to unsubscribe: $e';
      notifyListeners();
    }
  }

  // Fetch episodes for a podcast
  Future<void> fetchEpisodes(String podcastId, String feedUrl) async {
    try {
      _isLoading = true;
      notifyListeners();

      final episodes = await _api.fetchEpisodes(feedUrl, podcastId);

      if (episodes.isNotEmpty) {
        await _db.insertEpisodes(episodes);
        _podcastEpisodes[podcastId] = await _db.getEpisodesByPodcast(podcastId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch episodes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load episodes from database
  Future<void> loadEpisodes(String podcastId) async {
    try {
      final episodes = await _db.getEpisodesByPodcast(podcastId);
      _podcastEpisodes[podcastId] = episodes;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load episodes: $e';
      notifyListeners();
    }
  }

  // Refresh episodes for a podcast
  Future<void> refreshEpisodes(String podcastId, String feedUrl) async {
    await fetchEpisodes(podcastId, feedUrl);

    // Update last update time
    final podcast = await _db.getPodcast(podcastId);
    if (podcast != null) {
      final updatedPodcast = podcast.copyWith(lastUpdatedAt: DateTime.now());
      await _db.updatePodcast(updatedPodcast);
      await loadSubscribedPodcasts();
    }
  }

  // Check if podcast is subscribed
  bool isPodcastSubscribed(String podcastId) {
    return _subscribedPodcasts.any((p) => p.id == podcastId);
  }

  // Check if podcast is subscribed (async)
  Future<bool> isSubscribed(String podcastId) async {
    final podcast = await _db.getPodcast(podcastId);
    return podcast?.isSubscribed ?? false;
  }

  // Mark episode as played or unplayed
  Future<void> setEpisodePlayedStatus(String episodeId, bool isPlayed) async {
    try {
      await _db.updateEpisodePlayedStatus(episodeId, isPlayed);
      updateInMemoryPlayedStatus(episodeId, isPlayed);
    } catch (e) {
      _error = 'Failed to update episode played status: $e';
      notifyListeners();
    }
  }

  // Update in-memory played status
  void updateInMemoryPlayedStatus(String episodeId, bool isPlayed) {
    bool updated = false;
    for (final podcastId in _podcastEpisodes.keys) {
      final episodes = _podcastEpisodes[podcastId];
      if (episodes != null) {
        final index = episodes.indexWhere((e) => e.id == episodeId);
        if (index != -1) {
          episodes[index] = episodes[index].copyWith(
            isPlayed: isPlayed,
            playbackPosition: isPlayed ? 0 : episodes[index].playbackPosition,
          );
          updated = true;
        }
      }
    }
    if (updated) {
      notifyListeners();
    }
  }

  // Mark all episodes of a podcast as played or unplayed
  Future<void> setAllEpisodesPlayedStatus(
    String podcastId,
    bool isPlayed,
  ) async {
    try {
      await _db.updateAllEpisodesPlayedStatus(podcastId, isPlayed);
      final episodes = _podcastEpisodes[podcastId];
      if (episodes != null) {
        _podcastEpisodes[podcastId] = episodes
            .map(
              (e) => e.copyWith(
                isPlayed: isPlayed,
                playbackPosition: isPlayed ? 0 : e.playbackPosition,
              ),
            )
            .toList();
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update all episodes: $e';
      notifyListeners();
    }
  }
}

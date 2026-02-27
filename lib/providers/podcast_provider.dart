import 'package:flutter/material.dart';
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
  Future<void> searchPodcasts(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      _searchResults = await _api.searchPodcasts(query);

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
        _podcastEpisodes[podcastId] = episodes;
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
}

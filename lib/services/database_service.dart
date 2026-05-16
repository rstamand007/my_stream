import 'package:hive_flutter/hive_flutter.dart';
import '../models/podcast.dart';
import '../models/episode.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();

  static const String podcastBoxName = 'podcasts';
  static const String episodeBoxName = 'episodes';

  DatabaseService._internal();

  Future<Box<Podcast>> get podcastBox async =>
      Hive.box<Podcast>(podcastBoxName);
  Future<Box<Episode>> get episodeBox async =>
      Hive.box<Episode>(episodeBoxName);

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PodcastAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(EpisodeAdapter());
    }

    await Hive.openBox<Podcast>(podcastBoxName);
    await Hive.openBox<Episode>(episodeBoxName);
  }

  // Podcast CRUD operations
  Future<void> insertPodcast(Podcast podcast) async {
    final box = await podcastBox;
    await box.put(podcast.id, podcast);
  }

  Future<List<Podcast>> getSubscribedPodcasts() async {
    final box = await podcastBox;
    return box.values.where((p) => p.isSubscribed).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  Future<Podcast?> getPodcast(String id) async {
    final box = await podcastBox;
    return box.get(id);
  }

  Future<void> updatePodcast(Podcast podcast) async {
    final box = await podcastBox;
    await box.put(podcast.id, podcast);
  }

  Future<void> deletePodcast(String id) async {
    final box = await podcastBox;
    await box.delete(id);

    // Also delete associated episodes
    final epBox = await episodeBox;
    final episodeKeys = epBox.values
        .where((e) => e.podcastId == id)
        .map((e) => e.id)
        .toList();
    await epBox.deleteAll(episodeKeys);
  }

  // Episode CRUD operations
  Future<void> insertEpisode(Episode episode) async {
    final box = await episodeBox;
    await box.put(episode.id, episode);
  }

  Future<void> insertEpisodes(List<Episode> episodes) async {
    final box = await episodeBox;
    final Map<String, Episode> episodeMap = {
      for (var episode in episodes) episode.id: episode,
    };
    await box.putAll(episodeMap);
  }

  Future<List<Episode>> getEpisodesByPodcast(String podcastId) async {
    final box = await episodeBox;
    return box.values.where((e) => e.podcastId == podcastId).toList()
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
  }

  Future<List<Episode>> getDownloadedEpisodes() async {
    final box = await episodeBox;
    return box.values.where((e) => e.isDownloaded).toList()
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
  }

  Future<Episode?> getEpisode(String id) async {
    final box = await episodeBox;
    return box.get(id);
  }

  Future<void> updateEpisode(Episode episode) async {
    final box = await episodeBox;
    await box.put(episode.id, episode);
  }

  Future<void> deleteEpisode(String id) async {
    final box = await episodeBox;
    await box.delete(id);
  }

  // Playback history operations
  Future<void> savePlaybackPosition(String episodeId, int position) async {
    final box = await episodeBox;
    final episode = box.get(episodeId);
    if (episode != null) {
      final updatedEpisode = episode.copyWith(playbackPosition: position);
      await box.put(episodeId, updatedEpisode);
    }
  }

  Future<void> close() async {
    await Hive.close();
  }
}

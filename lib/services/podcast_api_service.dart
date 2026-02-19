import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:podcast_search/podcast_search.dart' as ps;
import 'package:webfeed_revised/webfeed_revised.dart';
import '../models/podcast.dart';
import '../models/episode.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class PodcastApiService {
  final _search = ps.Search();

  // Search for podcasts using iTunes API
  Future<List<Podcast>> searchPodcasts(String query) async {
    try {
      final result = await _search.search(
        query,
        country: ps.Country.unitedStates,
        attribute: ps.Attribute.title,
        limit: 25,
      );

      if (result.resultCount > 0) {
        return result.items
            .map(
              (item) => Podcast(
                id: item.collectionId.toString(),
                title: item.collectionName ?? '',
                author: item.artistName ?? '',
                description: item.collectionCensoredName ?? '',
                artworkUrl: item.artworkUrl600 ?? item.artworkUrl100 ?? '',
                feedUrl: item.feedUrl ?? '',
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      logger.e('Error searching podcasts', error: e);
      return [];
    }
  }

  // Fetch podcast details by ID
  Future<Podcast?> getPodcastById(String id) async {
    try {
      final url = Uri.parse('${ApiConstants.itunesLookupUrl}?id=$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultCount'] > 0) {
          return Podcast.fromJson(data['results'][0]);
        }
      }
      return null;
    } catch (e) {
      logger.e('Error fetching podcast', error: e);
      return null;
    }
  }

  // Fetch episodes from podcast RSS feed
  Future<List<Episode>> fetchEpisodes(String feedUrl, String podcastId) async {
    try {
      final response = await http.get(Uri.parse(feedUrl));

      if (response.statusCode == 200) {
        // Try parsing as RSS first
        try {
          final feed = RssFeed.parse(response.body);
          return _parseRssEpisodes(feed, podcastId);
        } catch (e) {
          // If RSS fails, try Atom
          try {
            final feed = AtomFeed.parse(response.body);
            return _parseAtomEpisodes(feed, podcastId);
          } catch (e) {
            logger.w('Error parsing feed as Atom', error: e);
            return [];
          }
        }
      }
      return [];
    } catch (e) {
      logger.e('Error fetching episodes', error: e);
      return [];
    }
  }

  List<Episode> _parseRssEpisodes(RssFeed feed, String podcastId) {
    return feed.items?.map((item) {
          // Find audio enclosure
          final audioUrl = item.enclosure?.url ?? '';

          // Parse duration
          final itunesDuration = item.itunes?.duration?.inSeconds ?? 0;

          return Episode(
            id: item.guid ?? item.link ?? '',
            podcastId: podcastId,
            title: item.title ?? 'Untitled Episode',
            description: item.description ?? item.content?.value ?? '',
            audioUrl: audioUrl,
            duration: itunesDuration,
            publishDate: item.pubDate ?? DateTime.now(),
          );
        }).toList() ??
        [];
  }

  List<Episode> _parseAtomEpisodes(AtomFeed feed, String podcastId) {
    return feed.items?.map((item) {
          // Find audio link
          String audioUrl = '';
          try {
            final audioLink = item.links?.firstWhere(
              (link) =>
                  (link.type?.contains('audio') ?? false) ||
                  link.rel == 'enclosure',
            );
            audioUrl = audioLink?.href ?? '';
          } catch (e) {
            // No audio link found
            audioUrl = '';
          }

          return Episode(
            id: item.id ?? '',
            podcastId: podcastId,
            title: item.title ?? 'Untitled Episode',
            description: item.summary ?? item.content ?? '',
            audioUrl: audioUrl,
            duration: 0, // Atom feeds typically don't include duration
            publishDate: item.updated ?? DateTime.now(),
          );
        }).toList() ??
        [];
  }

  // Get trending/featured podcasts (using a predefined search)
  Future<List<Podcast>> getTrendingPodcasts() async {
    // Since iTunes doesn't have a trending endpoint, we'll search for popular terms
    return await searchPodcasts('technology');
  }
}

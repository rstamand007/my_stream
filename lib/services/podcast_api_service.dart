import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:podcast_search/podcast_search.dart' as ps;
import 'package:webfeed_revised/webfeed_revised.dart';
import '../models/podcast.dart';
import '../models/episode.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class PodcastApiService {
  final _search = ps.Search();

  // Headers for HTTP requests
  static const Map<String, String> _headers = {
    'User-Agent':
        'MyStreamPodcastPlayer/1.0.0 (https://github.com/rstamand007/my_stream)',
    'Accept':
        'application/xml, application/rss+xml, application/atom+xml, application/json, text/xml',
  };

  // Search for podcasts using iTunes API
  Future<List<Podcast>> searchPodcasts(
    String query, {
    ps.Country? country,
    ps.Attribute? attribute,
    String? language,
  }) async {
    try {
      // If the parameter is optional and there is no value provided then remove the filter.
      // However, if the parameter is mandatory in the library, use Canada as default.
      final result = await _search.search(
        query,
        country: country ?? ps.Country.canada,
        attribute: attribute ?? ps.Attribute.description,
        language: language ?? '',
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
      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          logger.w('Empty response body from $url');
          return null;
        }
        final data = json.decode(response.body);
        if (data['resultCount'] > 0) {
          return Podcast.fromJson(data['results'][0]);
        }
      }
      return null;
    } catch (e) {
      logger.e('Error fetching podcast ID: $id', error: e);
      return null;
    }
  }

  // Fetch episodes from podcast RSS feed
  Future<List<Episode>> fetchEpisodes(String feedUrl, String podcastId) async {
    try {
      if (feedUrl.isEmpty) {
        logger.w('Empty feed URL for podcast ID: $podcastId');
        return [];
      }

      final response = await http
          .get(Uri.parse(feedUrl), headers: _headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          logger.w('Empty response body for feed: $feedUrl');
          return [];
        }

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
            logger.e('Error parsing feed as RSS or Atom: $feedUrl', error: e);
            return [];
          }
        }
      } else {
        logger.w(
          'Failed to fetch episodes from $feedUrl. Status: ${response.statusCode}',
        );
      }
      return [];
    } catch (e) {
      if (kIsWeb && e.toString().contains('Failed to fetch')) {
        logger.e(
          'CORS Error: Failed to fetch episodes from $feedUrl on Web. '
          'CBC and many other podcast providers do not allow cross-origin requests from web browsers. '
          'Please run the app on a native platform (Android/iOS) to fetch this feed.',
          error: e,
        );
      } else {
        logger.e('Error fetching episodes from $feedUrl', error: e);
      }
      return [];
    }
  }

  List<Episode> _parseRssEpisodes(RssFeed feed, String podcastId) {
    return feed.items?.map((item) {
          // Find audio enclosure
          final audioUrl = item.enclosure?.url ?? '';

          // Parse duration more robustly
          int duration = 0;
          try {
            if (item.itunes?.duration != null) {
              duration = item.itunes!.duration!.inSeconds;
            }

            if (duration == 0) {
              // Fallback if itunes duration is 0 or null - some feeds put it in other places
              // For now, we'll stick to what webfeed provides but ensure we don't crash
            }
          } catch (e) {
            logger.w(
              'Error parsing duration for episode: ${item.title}',
              error: e,
            );
          }

          return Episode(
            id: item.guid ?? item.link ?? '',
            podcastId: podcastId,
            title: item.title ?? 'Untitled Episode',
            description: item.description ?? item.content?.value ?? '',
            audioUrl: audioUrl,
            duration: duration,
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

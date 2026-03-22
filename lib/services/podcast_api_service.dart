import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:podcast_search/podcast_search.dart' as ps;
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
        country: country ?? ps.Country.none,
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
        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        final data = json.decode(body);
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
        try {
          final body = utf8.decode(response.bodyBytes, allowMalformed: true);
          final document = XmlDocument.parse(body);
          return _parseXmlEpisodes(document, podcastId);
        } catch (e) {
          logger.e('Error parsing feed: $feedUrl', error: e);
          return [];
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

  List<Episode> _parseXmlEpisodes(XmlDocument document, String podcastId) {
    try {
      final items = document.findAllElements('item');
      if (items.isNotEmpty) {
        return items.map((node) => _parseXmlItem(node, podcastId)).toList();
      }

      final entries = document.findAllElements('entry');
      if (entries.isNotEmpty) {
        return entries.map((node) => _parseXmlEntry(node, podcastId)).toList();
      }
    } catch (e) {
      logger.e('Error extracting episodes from XML', error: e);
    }
    return [];
  }

  Episode _parseXmlItem(XmlElement item, String podcastId) {
    final title = _getText(item, 'title') ?? 'Untitled Episode';
    final description =
        _getText(item, 'content:encoded') ??
        _getText(item, 'description') ??
        '';
    final guid = _getText(item, 'guid') ?? _getText(item, 'link') ?? '';

    String audioUrl = '';
    final enclosure = item.findElements('enclosure').firstOrNull;
    if (enclosure != null) {
      audioUrl = enclosure.getAttribute('url') ?? '';
    }

    int duration = 0;
    try {
      final itunesDuration = _getText(item, 'itunes:duration');
      if (itunesDuration != null) {
        final parts = itunesDuration.split(':');
        if (parts.length == 3) {
          duration =
              int.parse(parts[0]) * 3600 +
              int.parse(parts[1]) * 60 +
              int.parse(parts[2]);
        } else if (parts.length == 2) {
          duration = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        } else {
          duration = int.parse(parts[0]);
        }
      }
    } catch (_) {}

    DateTime pubDate = DateTime.now();
    final pubDateStr = _getText(item, 'pubDate');
    if (pubDateStr != null) {
      pubDate = _parseDate(pubDateStr);
    }

    return Episode(
      id: guid,
      podcastId: podcastId,
      title: title,
      description: description,
      audioUrl: audioUrl,
      duration: duration,
      publishDate: pubDate,
    );
  }

  Episode _parseXmlEntry(XmlElement entry, String podcastId) {
    final title = _getText(entry, 'title') ?? 'Untitled Episode';
    final description =
        _getText(entry, 'content') ?? _getText(entry, 'summary') ?? '';
    final id = _getText(entry, 'id') ?? '';

    String audioUrl = '';
    final links = entry.findElements('link');
    for (final link in links) {
      final type = link.getAttribute('type') ?? '';
      final rel = link.getAttribute('rel') ?? '';
      if (type.contains('audio') || rel == 'enclosure') {
        audioUrl = link.getAttribute('href') ?? '';
        break;
      }
    }

    DateTime pubDate = DateTime.now();
    final updatedStr =
        _getText(entry, 'updated') ?? _getText(entry, 'published');
    if (updatedStr != null) {
      pubDate = DateTime.tryParse(updatedStr) ?? DateTime.now();
    }

    return Episode(
      id: id,
      podcastId: podcastId,
      title: title,
      description: description,
      audioUrl: audioUrl,
      duration: 0,
      publishDate: pubDate,
    );
  }

  String? _getText(XmlElement node, String tag) {
    return node.findElements(tag).firstOrNull?.innerText.trim();
  }

  DateTime _parseDate(String dateStr) {
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) return dt;

      var str = dateStr;
      if (str.contains(',')) {
        str = str.split(',')[1].trim();
      }
      final parts = str.split(RegExp(r'\s+'));
      if (parts.length >= 4) {
        final day = parts[0].padLeft(2, '0');
        final monthStr = parts[1].toLowerCase();
        final year = parts[2];
        final timeStr = parts[3];

        const months = {
          'jan': '01',
          'feb': '02',
          'mar': '03',
          'apr': '04',
          'may': '05',
          'jun': '06',
          'jul': '07',
          'aug': '08',
          'sep': '09',
          'oct': '10',
          'nov': '11',
          'dec': '12',
        };
        final month = months[monthStr] ?? '01';

        final isoStr = '$year-$month-$day $timeStr';
        final parsed = DateTime.tryParse(isoStr);
        if (parsed != null) return parsed;
      }
    } catch (_) {}
    return DateTime.now();
  }

  // Get trending/featured podcasts (using a predefined search)
  Future<List<Podcast>> getTrendingPodcasts() async {
    // Since iTunes doesn't have a trending endpoint, we'll search for popular terms
    return await searchPodcasts('technology');
  }
}

import 'package:hive/hive.dart';

part 'episode.g.dart';

@HiveType(typeId: 1)
class Episode {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String podcastId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final String audioUrl;
  @HiveField(5)
  final int duration; // in seconds
  @HiveField(6)
  final DateTime publishDate;
  @HiveField(7)
  final bool isDownloaded;
  @HiveField(8)
  final String? localFilePath;
  @HiveField(9)
  final int? playbackPosition; // in seconds
  @HiveField(10)
  final String? artworkUrl;

  Episode({
    required this.id,
    required this.podcastId,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.duration,
    required this.publishDate,
    this.isDownloaded = false,
    this.localFilePath,
    this.playbackPosition,
    this.artworkUrl,
  });

  // Create from RSS feed item
  factory Episode.fromRss(Map<String, dynamic> rss, String podcastId) {
    return Episode(
      id: rss['guid'] ?? rss['link'] ?? '',
      podcastId: podcastId,
      title: rss['title'] ?? 'Untitled Episode',
      description: rss['description'] ?? '',
      audioUrl: rss['enclosure']?['url'] ?? '',
      duration: parseDuration(rss['duration']),
      publishDate:
          DateTime.tryParse(rss['pubDate'] ?? '') ??
          DateTime.tryParse(rss['pubDate']?.replaceFirst(' +0000', '') ?? '') ??
          DateTime.now(),
      artworkUrl: rss['itunes:image']?['@href'],
    );
  }

  // Create from database
  factory Episode.fromMap(Map<String, dynamic> map) {
    return Episode(
      id: map['id'],
      podcastId: map['podcastId'],
      title: map['title'],
      description: map['description'],
      audioUrl: map['audioUrl'],
      duration: map['duration'],
      publishDate: DateTime.fromMillisecondsSinceEpoch(map['publishDate']),
      isDownloaded: map['isDownloaded'] == 1,
      localFilePath: map['localFilePath'],
      playbackPosition: map['playbackPosition'],
      artworkUrl: map['artworkUrl'],
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'podcastId': podcastId,
      'title': title,
      'description': description,
      'audioUrl': audioUrl,
      'duration': duration,
      'publishDate': publishDate.millisecondsSinceEpoch,
      'isDownloaded': isDownloaded ? 1 : 0,
      'localFilePath': localFilePath,
      'playbackPosition': playbackPosition,
      'artworkUrl': artworkUrl,
    };
  }

  // Copy with method
  Episode copyWith({
    String? id,
    String? podcastId,
    String? title,
    String? description,
    String? audioUrl,
    int? duration,
    DateTime? publishDate,
    bool? isDownloaded,
    String? localFilePath,
    int? playbackPosition,
    String? artworkUrl,
  }) {
    return Episode(
      id: id ?? this.id,
      podcastId: podcastId ?? this.podcastId,
      title: title ?? this.title,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      publishDate: publishDate ?? this.publishDate,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localFilePath: localFilePath ?? this.localFilePath,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      artworkUrl: artworkUrl ?? this.artworkUrl,
    );
  }

  // Helper method to parse duration from various formats
  static int parseDuration(dynamic duration) {
    if (duration == null) return 0;
    if (duration is int) return duration;
    if (duration is String) {
      // Try to parse HH:MM:SS or MM:SS format
      final parts = duration
          .split(':')
          .map(int.tryParse)
          .whereType<int>()
          .toList();
      if (parts.length == 3) {
        return parts[0] * 3600 + parts[1] * 60 + parts[2];
      } else if (parts.length == 2) {
        return parts[0] * 60 + parts[1];
      } else if (parts.length == 1) {
        return parts[0];
      }
    }
    return 0;
  }

  // Get playback URL (local if downloaded, otherwise remote)
  String get playbackUrl =>
      isDownloaded && localFilePath != null ? localFilePath! : audioUrl;
}

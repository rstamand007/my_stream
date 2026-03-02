import 'package:hive/hive.dart';

part 'podcast.g.dart';

@HiveType(typeId: 0)
class Podcast {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String author;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final String artworkUrl;
  @HiveField(5)
  final String feedUrl;
  @HiveField(6)
  final bool isSubscribed;
  @HiveField(7)
  final DateTime? lastUpdatedAt;

  Podcast({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.artworkUrl,
    required this.feedUrl,
    this.isSubscribed = false,
    this.lastUpdatedAt,
  });

  // Create from JSON (iTunes API)
  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['collectionId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['collectionName'] ?? json['trackName'] ?? '',
      author: json['artistName'] ?? '',
      description: json['description'] ?? '',
      artworkUrl: json['artworkUrl600'] ?? json['artworkUrl100'] ?? '',
      feedUrl: json['feedUrl'] ?? '',
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.parse(json['lastUpdatedAt'])
          : null,
    );
  }

  // Create from database
  factory Podcast.fromMap(Map<String, dynamic> map) {
    return Podcast(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      description: map['description'],
      artworkUrl: map['artworkUrl'],
      feedUrl: map['feedUrl'],
      isSubscribed: map['isSubscribed'] == 1,
      lastUpdatedAt: map['lastUpdatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdatedAt'])
          : null,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'artworkUrl': artworkUrl,
      'feedUrl': feedUrl,
      'isSubscribed': isSubscribed ? 1 : 0,
      'lastUpdatedAt': lastUpdatedAt?.millisecondsSinceEpoch,
    };
  }

  // Copy with method for updating properties
  Podcast copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? artworkUrl,
    String? feedUrl,
    bool? isSubscribed,
    DateTime? lastUpdatedAt,
  }) {
    return Podcast(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      feedUrl: feedUrl ?? this.feedUrl,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

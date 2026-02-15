class Podcast {
  final String id;
  final String title;
  final String author;
  final String description;
  final String artworkUrl;
  final String feedUrl;
  final bool isSubscribed;

  Podcast({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.artworkUrl,
    required this.feedUrl,
    this.isSubscribed = false,
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
  }) {
    return Podcast(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      feedUrl: feedUrl ?? this.feedUrl,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}

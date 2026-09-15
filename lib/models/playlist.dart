import 'package:hive/hive.dart';

part 'playlist.g.dart';

@HiveType(typeId: 2)
class Playlist {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final List<String> episodeIds;
  @HiveField(3)
  final bool isSystem;
  @HiveField(4)
  final Map<String, int> playbackPositions;

  const Playlist({
    required this.id,
    required this.name,
    required this.episodeIds,
    this.isSystem = false,
    this.playbackPositions = const {},
  });

  Playlist copyWith({
    String? name,
    List<String>? episodeIds,
    Map<String, int>? playbackPositions,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      episodeIds: episodeIds ?? this.episodeIds,
      isSystem: isSystem,
      playbackPositions: playbackPositions ?? this.playbackPositions,
    );
  }
}

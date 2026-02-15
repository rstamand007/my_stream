import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/podcast.dart';
import '../models/episode.dart';
import '../utils/constants.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._internal();

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseConstants.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create podcasts table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.podcastsTable} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        description TEXT,
        artworkUrl TEXT,
        feedUrl TEXT NOT NULL,
        isSubscribed INTEGER DEFAULT 0
      )
    ''');

    // Create episodes table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.episodesTable} (
        id TEXT PRIMARY KEY,
        podcastId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        audioUrl TEXT NOT NULL,
        duration INTEGER DEFAULT 0,
        publishDate INTEGER NOT NULL,
        isDownloaded INTEGER DEFAULT 0,
        localFilePath TEXT,
        playbackPosition INTEGER DEFAULT 0,
        FOREIGN KEY (podcastId) REFERENCES ${DatabaseConstants.podcastsTable} (id) ON DELETE CASCADE
      )
    ''');

    // Create playback history table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.playbackHistoryTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        episodeId TEXT NOT NULL,
        playbackPosition INTEGER NOT NULL,
        lastPlayed INTEGER NOT NULL,
        FOREIGN KEY (episodeId) REFERENCES ${DatabaseConstants.episodesTable} (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute(
      'CREATE INDEX idx_episodes_podcast ON ${DatabaseConstants.episodesTable}(podcastId)',
    );
    await db.execute(
      'CREATE INDEX idx_episodes_published ON ${DatabaseConstants.episodesTable}(publishDate DESC)',
    );
  }

  // Podcast CRUD operations
  Future<void> insertPodcast(Podcast podcast) async {
    final db = await database;
    await db.insert(
      DatabaseConstants.podcastsTable,
      podcast.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Podcast>> getSubscribedPodcasts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.podcastsTable,
      where: 'isSubscribed = ?',
      whereArgs: [1],
      orderBy: 'title ASC',
    );
    return List.generate(maps.length, (i) => Podcast.fromMap(maps[i]));
  }

  Future<Podcast?> getPodcast(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.podcastsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Podcast.fromMap(maps.first);
  }

  Future<void> updatePodcast(Podcast podcast) async {
    final db = await database;
    await db.update(
      DatabaseConstants.podcastsTable,
      podcast.toMap(),
      where: 'id = ?',
      whereArgs: [podcast.id],
    );
  }

  Future<void> deletePodcast(String id) async {
    final db = await database;
    await db.delete(
      DatabaseConstants.podcastsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Episode CRUD operations
  Future<void> insertEpisode(Episode episode) async {
    final db = await database;
    await db.insert(
      DatabaseConstants.episodesTable,
      episode.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertEpisodes(List<Episode> episodes) async {
    final db = await database;
    final batch = db.batch();
    for (var episode in episodes) {
      batch.insert(
        DatabaseConstants.episodesTable,
        episode.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Episode>> getEpisodesByPodcast(String podcastId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.episodesTable,
      where: 'podcastId = ?',
      whereArgs: [podcastId],
      orderBy: 'publishDate DESC',
    );
    return List.generate(maps.length, (i) => Episode.fromMap(maps[i]));
  }

  Future<List<Episode>> getDownloadedEpisodes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.episodesTable,
      where: 'isDownloaded = ?',
      whereArgs: [1],
      orderBy: 'publishDate DESC',
    );
    return List.generate(maps.length, (i) => Episode.fromMap(maps[i]));
  }

  Future<Episode?> getEpisode(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.episodesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Episode.fromMap(maps.first);
  }

  Future<void> updateEpisode(Episode episode) async {
    final db = await database;
    await db.update(
      DatabaseConstants.episodesTable,
      episode.toMap(),
      where: 'id = ?',
      whereArgs: [episode.id],
    );
  }

  Future<void> deleteEpisode(String id) async {
    final db = await database;
    await db.delete(
      DatabaseConstants.episodesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Playback history operations
  Future<void> savePlaybackPosition(String episodeId, int position) async {
    final db = await database;

    // Update episode playback position
    await db.update(
      DatabaseConstants.episodesTable,
      {'playbackPosition': position},
      where: 'id = ?',
      whereArgs: [episodeId],
    );

    // Insert or update playback history
    await db.insert(
      DatabaseConstants.playbackHistoryTable,
      {
        'episodeId': episodeId,
        'playbackPosition': position,
        'lastPlayed': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

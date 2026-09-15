import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/episode_tile.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PlaylistProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            tooltip: 'Create playlist',
            icon: const Icon(Icons.playlist_add_rounded),
            onPressed: () => _showPlaylistEditor(context),
          ),
        ],
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.playlists.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.playlists.isEmpty) {
            return const Center(child: Text('No playlists yet'));
          }
          return RefreshIndicator(
            onRefresh: provider.load,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                for (final playlist in provider.playlists)
                  _buildPlaylist(context, provider, playlist),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylist(
    BuildContext context,
    PlaylistProvider provider,
    Playlist playlist,
  ) {
    final episodes = provider.episodesFor(playlist);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        leading: Icon(
          playlist.isSystem
              ? Icons.auto_awesome_rounded
              : Icons.queue_music_rounded,
        ),
        title: Text(playlist.name),
        subtitle: Text(
          '${episodes.length} episode${episodes.length == 1 ? '' : 's'}',
        ),
        trailing: playlist.isSystem
            ? const Tooltip(
                message: 'Generated playlist cannot be deleted',
                child: Icon(Icons.lock_outline_rounded),
              )
            : PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') _showPlaylistEditor(context, playlist);
                  if (action == 'delete') _confirmDelete(context, playlist);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
        children: episodes.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No episodes in this playlist'),
                ),
              ]
            : [
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: episodes.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final reorderedEpisodes = List.of(episodes);
                    final episode = reorderedEpisodes.removeAt(oldIndex);
                    reorderedEpisodes.insert(newIndex, episode);
                    provider.reorderPlaylist(
                      playlist,
                      reorderedEpisodes.map((item) => item.id).toList(),
                    );
                  },
                  itemBuilder: (context, index) {
                    final episode = episodes[index];
                    return EpisodeTile(
                      key: ValueKey(episode.id),
                      episode: episode,
                      onPlay: () => context.read<PlayerProvider>().playQueue(
                        episodes,
                        startIndex: index,
                      ),
                      dragHandle: kIsWeb
                          ? ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle_rounded),
                            )
                          : ReorderableDelayedDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle_rounded),
                            ),
                      playbackPosition: provider.playbackPositionFor(
                        playlist,
                        episode,
                      ),
                    );
                  },
                ),
              ],
      ),
    );
  }

  Future<void> _showPlaylistEditor(
    BuildContext context, [
    Playlist? playlist,
  ]) async {
    final provider = context.read<PlaylistProvider>();
    final nameController = TextEditingController(text: playlist?.name ?? '');
    final selectedIds = <String>[
      if (playlist != null)
        for (final episodeId in playlist.episodeIds)
          if (provider.allEpisodes.any((episode) => episode.id == episodeId))
            episodeId,
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                playlist == null ? 'Create playlist' : 'Edit playlist',
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: playlist == null,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Episodes'),
                    if (selectedIds.isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                        ),
                        child: ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: selectedIds.length,
                          onReorder: (oldIndex, newIndex) {
                            setDialogState(() {
                              if (oldIndex < newIndex) newIndex -= 1;
                              final episodeId = selectedIds.removeAt(oldIndex);
                              selectedIds.insert(newIndex, episodeId);
                            });
                          },
                          itemBuilder: (context, index) {
                            final episodeId = selectedIds[index];
                            final episode = provider.allEpisodes.firstWhere(
                              (item) => item.id == episodeId,
                            );
                            return CheckboxListTile(
                              key: ValueKey(episode.id),
                              dense: true,
                              value: true,
                              title: Text(
                                episode.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(episode.podcastId),
                              secondary: kIsWeb
                                  ? ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(
                                        Icons.drag_handle_rounded,
                                      ),
                                    )
                                  : ReorderableDelayedDragStartListener(
                                      index: index,
                                      child: const Icon(
                                        Icons.drag_handle_rounded,
                                      ),
                                    ),
                              onChanged: (selected) {
                                if (selected == false) {
                                  setDialogState(
                                    () => selectedIds.remove(episode.id),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    if (provider.allEpisodes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Refresh podcasts to add episodes.'),
                      ),
                    for (final episode in provider.allEpisodes)
                      if (!selectedIds.contains(episode.id))
                        CheckboxListTile(
                          dense: true,
                          value: selectedIds.contains(episode.id),
                          title: Text(
                            episode.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(episode.podcastId),
                          onChanged: (selected) {
                            setDialogState(() {
                              if (selected == true) {
                                if (!selectedIds.contains(episode.id)) {
                                  selectedIds.add(episode.id);
                                }
                              } else {
                                selectedIds.remove(episode.id);
                              }
                            });
                          },
                        ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (playlist == null) {
                      await provider.createPlaylist(
                        nameController.text,
                        selectedIds,
                      );
                    } else {
                      await provider.updatePlaylist(
                        playlist.copyWith(
                          name: nameController.text,
                          episodeIds: selectedIds,
                        ),
                      );
                    }
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    nameController.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete playlist?'),
        content: Text('Delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<PlaylistProvider>().deletePlaylist(playlist);
    }
  }
}

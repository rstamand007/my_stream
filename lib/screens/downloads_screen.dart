import 'package:flutter/material.dart';
import 'package:my_stream/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../widgets/episode_tile.dart';
import '../utils/formatters.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.downloads,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add_rounded),
            tooltip: l10n.addFiles,
            onPressed: () => context.read<DownloadProvider>().pickLocalFiles(),
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_rounded),
            tooltip: l10n.addFolder,
            onPressed: () =>
                context.read<DownloadProvider>().pickLocalDirectory(),
          ),
          Consumer<DownloadProvider>(
            builder: (context, provider, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: provider.isAutoplayEnabled,
                    onChanged: (value) {
                      if (value != null) provider.toggleAutoplay(value);
                    },
                  ),
                  Text(
                    'Autoplay',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
          Consumer<DownloadProvider>(
            builder: (context, provider, child) {
              if (provider.downloadedEpisodes.isEmpty) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text(l10n.clearAllDownloads),
                    onTap: () {
                      Future.delayed(Duration.zero, () {
                        if (!context.mounted) return;
                        _showClearDialog(context, l10n);
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<DownloadProvider>(
        builder: (context, provider, child) {
          if (provider.downloadedEpisodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_outlined,
                    size: 80,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noDownloads,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.downloadedAppearHere,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Storage info
              FutureBuilder<int>(
                future: provider.getTotalDownloadSize(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.storage_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.storageUsed,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                Formatters.formatFileSize(snapshot.data!),
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Downloaded episodes list
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: provider.downloadedEpisodes.length,
                  onReorder: (oldIndex, newIndex) {
                    provider.reorderDownloads(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final episode = provider.downloadedEpisodes[index];
                    return EpisodeTile(
                      key: ValueKey(episode.id),
                      episode: episode,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClearDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearDownloadsTitle),
        content: Text(l10n.clearDownloadsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<DownloadProvider>().clearAllDownloads();
              Navigator.pop(context);
            },
            child: Text(
              l10n.clearAll,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

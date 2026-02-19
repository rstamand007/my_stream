import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../widgets/episode_tile.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Downloads',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<DownloadProvider>(
            builder: (context, provider, child) {
              if (provider.downloadedEpisodes.isEmpty) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Clear all downloads'),
                    onTap: () {
                      Future.delayed(Duration.zero, () {
                        if (!context.mounted) return;
                        _showClearDialog(context);
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
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No downloads yet',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Downloaded episodes appear here',
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
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.storage_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Storage Used',
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
                child: ListView.builder(
                  itemCount: provider.downloadedEpisodes.length,
                  itemBuilder: (context, index) {
                    return EpisodeTile(
                      episode: provider.downloadedEpisodes[index],
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

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Downloads'),
        content: const Text(
          'Are you sure you want to delete all downloaded episodes? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<DownloadProvider>().clearAllDownloads();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/episode.dart';
import '../providers/player_provider.dart';
import '../providers/download_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../screens/now_playing_screen.dart';

class EpisodeTile extends StatelessWidget {
  final Episode episode;

  const EpisodeTile({super.key, required this.episode});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, DownloadProvider>(
      builder: (context, playerProvider, downloadProvider, child) {
        final isPlaying =
            playerProvider.currentEpisode?.id == episode.id &&
            playerProvider.isPlaying;
        final isCurrentEpisode =
            playerProvider.currentEpisode?.id == episode.id;
        final isDownloaded = downloadProvider.isDownloaded(episode.id);
        final isDownloading = downloadProvider.isDownloading(episode.id);
        final downloadProgress = downloadProvider.getProgress(episode.id);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrentEpisode
                ? AppColors.primary.withValues(alpha: 0.1)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: _buildPlayButton(context, playerProvider, isPlaying),
            title: Text(
              episode.title,
              style: TextStyle(
                color: isCurrentEpisode
                    ? AppColors.primary
                    : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: isCurrentEpisode
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${Formatters.formatDate(episode.publishDate)} • ${Formatters.formatDuration(episode.duration)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: downloadProgress,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
            trailing: _buildDownloadButton(
              context,
              downloadProvider,
              isDownloaded,
              isDownloading,
            ),
            onTap: () {
              if (isCurrentEpisode) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NowPlayingScreen(),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildPlayButton(
    BuildContext context,
    PlayerProvider playerProvider,
    bool isPlaying,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
        ),
        onPressed: () {
          if (playerProvider.currentEpisode?.id == episode.id) {
            playerProvider.togglePlayPause();
          } else {
            playerProvider.playEpisode(episode);
          }
        },
      ),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context,
    DownloadProvider downloadProvider,
    bool isDownloaded,
    bool isDownloading,
  ) {
    if (isDownloading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return IconButton(
      icon: Icon(
        isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
        color: isDownloaded
            ? AppColors.success
            : Theme.of(context).iconTheme.color,
      ),
      onPressed: () {
        if (isDownloaded) {
          downloadProvider.deleteDownload(episode);
        } else {
          downloadProvider.downloadEpisode(episode);
        }
      },
    );
  }
}

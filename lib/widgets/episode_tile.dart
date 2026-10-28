import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/episode.dart';
import '../providers/player_provider.dart';
import '../providers/download_provider.dart';
import '../providers/podcast_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'package:my_stream/l10n/app_localizations.dart';
import '../screens/now_playing_screen.dart';

class EpisodeTile extends StatelessWidget {
  final Episode episode;
  final int? playbackPosition;
  final VoidCallback? onPlay;
  final Widget? dragHandle;
  final void Function(bool isPlayed)? onTogglePlayed;

  const EpisodeTile({
    super.key,
    required this.episode,
    this.playbackPosition,
    this.onPlay,
    this.dragHandle,
    this.onTogglePlayed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
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
                    ? Theme.of(context).colorScheme.primary
                    : (episode.isPlayed
                        ? Theme.of(context).textTheme.bodyMedium?.color
                        : Theme.of(context).textTheme.bodyLarge?.color),
                fontWeight: isCurrentEpisode
                    ? FontWeight.bold
                    : (episode.isPlayed ? FontWeight.normal : FontWeight.w500),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (episode.isPlayed) ...[
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Theme.of(context)
                                .extension<AppThemeExtension>()
                                ?.success ??
                            Colors.green,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        episode.isPlayed
                            ? '${l10n.played} • ${episode.podcastId == 'local' ? l10n.localFile : Formatters.formatDate(episode.publishDate)} • ${Formatters.formatDuration(episode.duration)}'
                            : (episode.podcastId == 'local'
                                ? '${l10n.localFile} • ${Formatters.formatDuration(episode.duration)}'
                                : '${Formatters.formatDate(episode.publishDate)} • ${Formatters.formatDuration(episode.duration)}'),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: downloadProgress,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dragHandle != null) dragHandle!,
                if (playbackPosition != null && playbackPosition! > 0) ...[
                  Icon(
                    Icons.history_rounded,
                    size: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatDuration(playbackPosition!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 4),
                ],
                _buildDownloadButton(
                  context,
                  downloadProvider,
                  isDownloaded,
                  isDownloading,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: episode.isPlayed
                      ? l10n.markAsUnplayed
                      : l10n.markAsPlayed,
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'toggle_played',
                      child: Row(
                        children: [
                          Icon(
                            episode.isPlayed
                                ? Icons.mark_email_unread_outlined
                                : Icons.check_circle_outline_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            episode.isPlayed
                                ? l10n.markAsUnplayed
                                : l10n.markAsPlayed,
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'toggle_played') {
                      final newStatus = !episode.isPlayed;
                      if (onTogglePlayed != null) {
                        onTogglePlayed!(newStatus);
                      } else {
                        context
                            .read<PodcastProvider>()
                            .setEpisodePlayedStatus(episode.id, newStatus);
                      }
                    }
                  },
                ),
              ],
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
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: () {
          if (playerProvider.currentEpisode?.id == episode.id) {
            playerProvider.togglePlayPause();
          } else {
            onPlay?.call();
            if (onPlay == null) playerProvider.playEpisode(episode);
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
            ? (Theme.of(context).extension<AppThemeExtension>()?.success ??
                  Colors.green)
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

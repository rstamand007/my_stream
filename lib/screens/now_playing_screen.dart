import 'package:flutter/material.dart';
import 'package:my_stream/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../providers/podcast_provider.dart';
import '../widgets/neumorphic_icon_button.dart';
import '../utils/formatters.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: Center(
          child: NeumorphicIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).pop(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
        ),
        title: Text(l10n.nowPlaying),
        actions: [
          Consumer<PlayerProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<double>(
                icon: const Icon(Icons.speed_rounded),
                onSelected: (speed) {
                  provider.setSpeed(speed);
                },
                itemBuilder: (context) => _speeds
                    .map(
                      (speed) => PopupMenuItem(
                        value: speed,
                        child: Row(
                          children: [
                            if (provider.speed == speed)
                              Icon(
                                Icons.check_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              )
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 8),
                            Text(Formatters.formatSpeed(speed)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, provider, child) {
          if (provider.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: provider.stop,
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!provider.hasEpisode) {
            return Center(child: Text(l10n.noEpisodePlaying));
          }

          final episode = provider.currentEpisode!;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),

                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Artwork Image or Placeholder icon
                      ClipRRect(
                        borderRadius: BorderRadius.circular(140),
                        child: _buildArtwork(context, episode),
                      ),
                      // Description Overlay
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            Formatters.stripHtml(episode.description),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.white,
                              shadows: [
                                const Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Episode title
                Text(
                  episode.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 32),

                // Progress slider
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: provider.position.inSeconds.toDouble(),
                        max: provider.duration.inSeconds.toDouble().clamp(
                          1.0,
                          double.infinity,
                        ),
                        onChanged: (value) {
                          provider.seek(Duration(seconds: value.toInt()));
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        inactiveColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Formatters.formatDuration(
                              provider.position.inSeconds,
                            ),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            Formatters.formatDuration(
                              provider.duration.inSeconds,
                            ),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Playback controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    NeumorphicIconButton(
                      icon: Icons.replay_10_rounded,
                      size: 60,
                      onPressed: provider.skipBackward,
                    ),
                    NeumorphicIconButton(
                      icon: provider.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 84,
                      onPressed: provider.togglePlayPause,
                    ),
                    NeumorphicIconButton(
                      icon: Icons.forward_30_rounded,
                      size: 60,
                      onPressed: provider.skipForward,
                    ),
                  ],
                ),

                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtwork(BuildContext context, dynamic episode) {
    // Try to get artwork from episode first
    String? imageUrl = episode.artworkUrl;

    // If not in episode, try to get it from the podcast
    if (imageUrl == null || imageUrl.isEmpty) {
      try {
        final podcast = context
            .read<PodcastProvider>()
            .subscribedPodcasts
            .firstWhere((p) => p.id == episode.podcastId);
        imageUrl = podcast.artworkUrl;
      } catch (_) {
        // Podcast not found in subscribed list
      }
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.4),
          BlendMode.darken,
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 280,
          height: 280,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => _buildPlaceholderIcon(),
        ),
      );
    }

    return _buildPlaceholderIcon();
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.podcasts,
        size: 120,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      ),
    );
  }
}

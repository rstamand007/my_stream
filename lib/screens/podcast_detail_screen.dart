import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/podcast.dart';
import '../providers/podcast_provider.dart';
import '../widgets/episode_tile.dart';
import '../utils/constants.dart';

class PodcastDetailScreen extends StatefulWidget {
  final Podcast podcast;

  const PodcastDetailScreen({super.key, required this.podcast});

  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule episode loading after the first frame to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEpisodes();
    });
  }

  Future<void> _loadEpisodes() async {
    final provider = context.read<PodcastProvider>();
    if (widget.podcast.isSubscribed) {
      await provider.loadEpisodes(widget.podcast.id);
    } else {
      await provider.fetchEpisodes(widget.podcast.id, widget.podcast.feedUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with podcast artwork
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.podcast.artworkUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surface,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.podcasts, size: 40),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withValues(alpha: 0.7),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Podcast info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.podcast.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.podcast.author,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // Subscribe button
                  Consumer<PodcastProvider>(
                    builder: (context, provider, child) {
                      final isSubscribed = widget.podcast.isSubscribed;

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (isSubscribed) {
                              await provider.unsubscribeFromPodcast(
                                widget.podcast.id,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } else {
                              await provider.subscribeToPodcast(widget.podcast);
                              setState(() {});
                            }
                          },
                          icon: Icon(
                            isSubscribed
                                ? Icons.replay_10_rounded
                                : Icons.add_circle_outline_rounded,
                          ),
                          label: Text(
                            isSubscribed ? 'Subscribed' : 'Subscribe',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSubscribed
                                ? AppColors.success
                                : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Description
                  if (widget.podcast.description.isNotEmpty) ...[
                    Text(
                      'About',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.podcast.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    'Episodes',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),

          // Episodes list
          Consumer<PodcastProvider>(
            builder: (context, provider, child) {
              final episodes = provider.getEpisodes(widget.podcast.id);

              if (provider.isLoading && episodes.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (episodes.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No episodes available',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return EpisodeTile(episode: episodes[index]);
                }, childCount: episodes.length),
              );
            },
          ),
        ],
      ),
    );
  }
}

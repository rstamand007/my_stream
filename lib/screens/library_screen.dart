import 'package:flutter/material.dart';
import 'package:my_stream/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/podcast_provider.dart';
import '../widgets/podcast_card.dart';
import '../widgets/neumorphic_icon_button.dart';
import 'podcast_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically load podcasts when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PodcastProvider>().loadSubscribedPodcasts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myLibrary,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: NeumorphicIconButton(
                icon: Icons.refresh_rounded,
                onPressed: () {
                  context.read<PodcastProvider>().loadSubscribedPodcasts();
                },
                tooltip: l10n.refresh,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<PodcastProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.subscribedPodcasts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.subscribedPodcasts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_music_outlined,
                    size: 80,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noPodcasts,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.searchToStart,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: provider.subscribedPodcasts.length,
              itemBuilder: (context, index) {
                final podcast = provider.subscribedPodcasts[index];
                return PodcastCard(
                  podcast: podcast,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PodcastDetailScreen(podcast: podcast),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

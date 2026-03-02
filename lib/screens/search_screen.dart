import 'package:flutter/material.dart';
import 'package:my_stream/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:podcast_search/podcast_search.dart' as ps;
import 'dart:async';
import '../providers/podcast_provider.dart';
import '../widgets/podcast_card.dart';
import 'podcast_detail_screen.dart';
import '../utils/constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  ps.Country? _selectedCountry;
  ps.Attribute _selectedAttribute = ps.Attribute.description;
  String? _selectedLanguage;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(AppDurations.searchDebounce, () {
      context.read<PodcastProvider>().searchPodcasts(
        query,
        country: _selectedCountry,
        attribute: _selectedAttribute,
        language: _selectedLanguage,
      );
    });
  }

  void _onCountryChanged(ps.Country? value) {
    setState(() {
      _selectedCountry = value;
    });
    context.read<PodcastProvider>().searchPodcasts(
      _searchController.text,
      country: _selectedCountry,
      attribute: _selectedAttribute,
      language: _selectedLanguage,
    );
  }

  void _onAttributeChanged(ps.Attribute? value) {
    if (value == null) return;
    setState(() {
      _selectedAttribute = value;
    });
    context.read<PodcastProvider>().searchPodcasts(
      _searchController.text,
      country: _selectedCountry,
      attribute: _selectedAttribute,
      language: _selectedLanguage,
    );
  }

  void _onLanguageChanged(String? value) {
    setState(() {
      _selectedLanguage = value;
    });
    context.read<PodcastProvider>().searchPodcasts(
      _searchController.text,
      country: _selectedCountry,
      attribute: _selectedAttribute,
      language: _selectedLanguage,
    );
  }

  String _getCountryName(ps.Country country) {
    try {
      final name = country.toString().split('.').last;
      final result = name.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => ' ${match.group(0)}',
      );
      return result[0].toUpperCase() + result.substring(1);
    } catch (e) {
      return country.toString();
    }
  }

  String _getAttributeName(ps.Attribute attribute) {
    switch (attribute) {
      case ps.Attribute.title:
        return 'Title';
      case ps.Attribute.author:
        return 'Author';
      case ps.Attribute.description:
        return 'Description';
      case ps.Attribute.keywords:
        return 'Keywords';
      default:
        return attribute.toString().split('.').last.toUpperCase();
    }
  }

  String _getLanguageName(String? code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'French';
      case 'es':
        return 'Spanish';
      case 'de':
        return 'German';
      case 'it':
        return 'Italian';
      case 'ja':
        return 'Japanese';
      case 'zh':
        return 'Chinese';
      default:
        return 'Global';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.searchPodcasts,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search bar, Country, Attribute and Language selection
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              context.read<PodcastProvider>().searchPodcasts(
                                '',
                                country: _selectedCountry,
                                attribute: _selectedAttribute,
                                language: _selectedLanguage,
                              );
                            },
                          )
                        : null,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filters Row 1: Country & Attribute
                Row(
                  children: [
                    // Country Dropdown
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.public_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<ps.Country?>(
                                value: _selectedCountry,
                                isExpanded: true,
                                hint: const Text('Global'),
                                items: [
                                  const DropdownMenuItem<ps.Country?>(
                                    value: null,
                                    child: Text('Global'),
                                  ),
                                  // Show common countries first for better UX
                                  ...[
                                    ps.Country.canada,
                                    ps.Country.unitedStates,
                                    ps.Country.unitedKingdom,
                                    ps.Country.france,
                                  ].map((country) {
                                    return DropdownMenuItem<ps.Country?>(
                                      value: country,
                                      child: Text(_getCountryName(country)),
                                    );
                                  }),
                                ],
                                onChanged: _onCountryChanged,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Attribute Dropdown
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sort_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<ps.Attribute>(
                                value: _selectedAttribute,
                                isExpanded: true,
                                items:
                                    [
                                      ps.Attribute.description,
                                      ps.Attribute.title,
                                      ps.Attribute.author,
                                      ps.Attribute.keywords,
                                    ].map((attribute) {
                                      return DropdownMenuItem<ps.Attribute>(
                                        value: attribute,
                                        child: Text(
                                          _getAttributeName(attribute),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: _onAttributeChanged,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Filters Row 2: Language
                Row(
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedLanguage,
                          isExpanded: true,
                          hint: const Text('Select Language (Global)'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Global'),
                            ),
                            ...['en', 'fr', 'es', 'de', 'it', 'ja', 'zh'].map((
                              lang,
                            ) {
                              return DropdownMenuItem<String?>(
                                value: lang,
                                child: Text(_getLanguageName(lang)),
                              );
                            }),
                          ],
                          onChanged: _onLanguageChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search results
          Expanded(
            child: Consumer<PodcastProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_searchController.text.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.searchPodcasts,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.findShows,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                if (provider.searchResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noResults,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tryDifferentSearch,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: provider.searchResults.length,
                    itemBuilder: (context, index) {
                      final podcast = provider.searchResults[index];
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
          ),
        ],
      ),
    );
  }
}

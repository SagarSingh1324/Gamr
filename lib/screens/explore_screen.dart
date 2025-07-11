import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/game_instance.dart';
import '../providers/explore_provider.dart';
import '../widgets/game_instance_card_big.dart';
import '../providers/internet_status_provider.dart';
import '../utilities/internet_checker.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToLibrary;
  const ExploreScreen({super.key, this.onNavigateToLibrary});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

// Search query state
final searchQueryProvider = StateProvider<String?>((ref) => null);

// Global TextEditingController provider
final searchTextControllerProvider = StateProvider<TextEditingController>((ref) {
  return TextEditingController();
});

// Search results provider 
final searchResultsProvider = FutureProvider<List<GameInstance>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query == null || query.trim().isEmpty) return [];

  return await ref.read(exploreProvider.notifier).fetchByName(query);
});

// Global ExploreScreen refreshed once or not flag
final exploreRefreshedOnceProvider = StateProvider<bool>((ref) => false);

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  bool _hasCheckedInternet = false;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkInitialInternet();
  }

  Future<void> _checkInitialInternet() async {
    final result = await hasInternetConnection();
    if (mounted) {
      setState(() {
        _hasCheckedInternet = true;
        _hasInternet = result;
      });

      final hasRefreshed = ref.read(exploreRefreshedOnceProvider);
      if (result && !hasRefreshed) {
        ref.read(exploreProvider.notifier).refreshItems();
        ref.read(exploreRefreshedOnceProvider.notifier).state = true;
      }
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // React to connection state changes
    ref.listen<AsyncValue<ConnectivityResult>>(internetStatusProvider, (prev, next) async {
      if (next is AsyncData) {
        final connected = await hasInternetConnection();

        if (mounted) {
          setState(() => _hasInternet = connected);

          final hasRefreshed = ref.read(exploreRefreshedOnceProvider);
          if (connected && !hasRefreshed) {
            ref.read(exploreProvider.notifier).refreshItems();
            ref.read(exploreRefreshedOnceProvider.notifier).state = true;
          }
        }
      }
    });

    final exploreAsync = ref.watch(exploreProvider);
    final exploreNotifier = ref.read(exploreProvider.notifier);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final searchController = ref.watch(searchTextControllerProvider);

    final isSearching = searchQuery != null && searchQuery.isNotEmpty;

    if (!_hasCheckedInternet) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasInternet) {
      return Scaffold(
        appBar: AppBar(title: const Text('By Genre')),
        body: const Center(
          child: Text(
            'No internet connection',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('By Genre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(exploreProvider.notifier).refreshItems();
              ref.read(exploreRefreshedOnceProvider.notifier).state = true;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Enter game name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = null;
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) {},
              onSubmitted: (value) {
                ref.read(searchQueryProvider.notifier).state = value.trim();
                FocusScope.of(context).unfocus();
              },
            ),
          ),
          Expanded(
            child: isSearching
                ? searchResults.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
                    ),
                    data: (results) {
                      if (results.isEmpty) {
                        return const Center(child: Text('No results found.'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GameInstanceCardBig(
                              item: results[index],
                              ref: ref,
                              onNavigateToLibrary: widget.onNavigateToLibrary,
                            ),
                          );
                        },
                      );
                    },
                  )
                : exploreAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: $error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => exploreNotifier.refreshItems(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (genreMap) {
                      final availableGenres = exploreNotifier.getAvailableGenres();
                      final hasData = genreMap.values.any((games) => games.isNotEmpty);
                      if (!hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final isStillLoading = genreMap.length < availableGenres.length;
                      return ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          ...availableGenres.map((genre) {
                            final gamesForGenre = genreMap[genre] ?? [];
                            if (gamesForGenre.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildHorizontalList(context, ref, genre, gamesForGenre),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                          if (isStillLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(
    BuildContext context,
    WidgetRef ref,
    String genre,
    List<GameInstance> games,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          genre,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: games.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GameInstanceCardBig(
                  item: games[index],
                  ref: ref,
                  onNavigateToLibrary: widget.onNavigateToLibrary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

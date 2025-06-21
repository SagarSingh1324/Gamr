import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';
import '../notifiers/explore_notifier.dart';
import '../widgets/game_card_big.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

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

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exploreAsync = ref.watch(exploreProvider);
    final exploreNotifier = ref.read(exploreProvider.notifier);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final searchController = ref.watch(searchTextControllerProvider);

    final isSearching = searchQuery != null && searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => exploreNotifier.refreshItems(),
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
              onChanged: (_) {}, // No need for setState
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
                            child: GameInstanceCardBig(item: results[index], ref: ref),
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

  Widget _buildHorizontalList(BuildContext context, WidgetRef ref, String genre, List<GameInstance> games) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          genre,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 300, // Adjust to your card size
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: games.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GameInstanceCardBig(item: games[index], ref: ref),
              );
            },
          ),
        ),
      ],
    );
  }
}

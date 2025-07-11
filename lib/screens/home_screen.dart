import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/game_instance.dart';
import '../providers/home_provider.dart';
import '../widgets/game_instance_card_big.dart';
import '../providers/internet_status_provider.dart';
import '../utilities/internet_checker.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToLibrary;

  const HomeScreen({super.key, this.onNavigateToLibrary});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// Global HomeScreen refreshed once or not flag
final homeRefreshedOnceProvider = StateProvider<bool>((ref) => false);

class _HomeScreenState extends ConsumerState<HomeScreen> {
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

      final hasRefreshed = ref.read(homeRefreshedOnceProvider);
      if (result && !hasRefreshed) {
        ref.read(homeProvider.notifier).refreshItems();
        ref.read(homeRefreshedOnceProvider.notifier).state = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ConnectivityResult>>(internetStatusProvider, (prev, next) async {
      if (next is AsyncData) {
        final connected = await hasInternetConnection();

        if (mounted) {
          setState(() => _hasInternet = connected);

          final hasRefreshed = ref.read(homeRefreshedOnceProvider);
          if (connected && !hasRefreshed) {
            ref.read(homeProvider.notifier).refreshItems();
            ref.read(homeRefreshedOnceProvider.notifier).state = true;
          }
        }
      }
    });

    final homeAsync = ref.watch(homeProvider);
    final homeNotifier = ref.read(homeProvider.notifier);

    if (!_hasCheckedInternet) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasInternet) {
      return Scaffold(
        appBar: AppBar(title: const Text('Popular Now')),
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
        title: const Text('Popular Now'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(homeProvider.notifier).refreshItems();
              ref.read(homeRefreshedOnceProvider.notifier).state = true;
            },
          ),
        ],
      ),
      body: homeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => homeNotifier.refreshItems(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (categoryMap) {
          final popTypes = homeNotifier.popTypes;
          final hasData = categoryMap.values.any((games) => games.isNotEmpty);

          if (!hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final isStillLoading = categoryMap.length < popTypes.length;

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              ...popTypes.map((popType) {
                final popTypeKey = popType.toString();
                final games = categoryMap[popTypeKey] ?? [];
                final categoryName = homeNotifier.getPopularityName(popType);

                if (games.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildHorizontalList(context, ref, categoryName, games),
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
    );
  }

  Widget _buildHorizontalList(
    BuildContext context,
    WidgetRef ref,
    String category,
    List<GameInstance> games,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: games.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 8 : 0,
                  right: 8,
                ),
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

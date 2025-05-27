import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/explore_viewmodel.dart';
import '../models/explore_item.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreViewModel>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ExploreViewModel>().refreshItems();
            },
          ),
        ],
      ),
      body: Consumer<ExploreViewModel>(
        builder: (context, viewModel, child) {
          // Loading state
          if (viewModel.isLoading && viewModel.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading explore items...'),
                ],
              ),
            );
          }

          // Error state
          if (viewModel.error != null && viewModel.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${viewModel.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.clearError();
                      viewModel.loadItems();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (viewModel.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No items found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // Success state with data
          return RefreshIndicator(
            onRefresh: () => viewModel.refreshItems(),
            child: Column(
              children: [
                // Show error banner if there's an error but we still have data
                if (viewModel.error != null)
                  Container(
                    width: double.infinity,
                    color: Colors.red.shade100,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Error: ${viewModel.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => viewModel.clearError(),
                        ),
                      ],
                    ),
                  ),
                
                // Loading indicator when refreshing
                if (viewModel.isLoading)
                  const LinearProgressIndicator(),
                
                // Items list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: viewModel.items.length,
                    itemBuilder: (context, index) {
                      final item = viewModel.items[index];
                      return _buildExploreItemCard(item);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExploreItemCard(ExploreItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            item.id.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text('ID: ${item.id}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Handle item tap - navigate to details or show dialog
          _showItemDetails(item);
        },
      ),
    );
  }

  void _showItemDetails(ExploreItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(item.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${item.id}'),
              const SizedBox(height: 8),
              Text('Name: ${item.name}'),
              // Add more details here as your model expands
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
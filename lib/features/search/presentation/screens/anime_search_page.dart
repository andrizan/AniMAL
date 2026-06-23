import 'package:animal/data/models/anime.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/features/search/presentation/providers/search_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search page for finding anime by keyword or browsing the ranking.
class AnimeSearchPage extends ConsumerStatefulWidget {
  const AnimeSearchPage({super.key});

  @override
  ConsumerState<AnimeSearchPage> createState() => _AnimeSearchPageState();
}

class _AnimeSearchPageState extends ConsumerState<AnimeSearchPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncAnime = _query.isEmpty
        ? ref.watch(animeRankingProvider)
        : ref.watch(animeSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search anime…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: asyncAnime.when(
              data: (list) => _AnimeListView(anime: list),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimeListView extends StatelessWidget {
  const _AnimeListView({required this.anime});

  final List<Anime> anime;

  @override
  Widget build(BuildContext context) {
    if (anime.isEmpty) {
      return const Center(child: Text('No results'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: anime.length,
      itemBuilder: (context, index) {
        return AnimeCard(anime: anime[index]);
      },
    );
  }
}

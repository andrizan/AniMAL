import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/features/search/providers/search_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/shared/widgets/empty_view.dart';
import 'package:animal/shared/widgets/error_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.md,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search anime…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
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
              skipLoadingOnReload: true,
              data: (list) => _AnimeListView(anime: list),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorView(
                message: 'Failed to load results',
                onRetry: () => ref.invalidate(
                  _query.isEmpty
                      ? animeRankingProvider
                      : animeSearchProvider(_query),
                ),
              ),
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
      return const EmptyView(icon: Icons.search_off, message: 'No results');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemExtent: 126,
      itemCount: anime.length,
      itemBuilder: (context, index) {
        return AnimeCard(anime: anime[index]);
      },
    );
  }
}

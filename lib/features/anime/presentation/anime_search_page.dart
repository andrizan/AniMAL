import 'package:animal/features/anime/domain/anime.dart';
import 'package:animal/features/anime/presentation/anime_search_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
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
      itemCount: anime.length,
      itemBuilder: (context, index) {
        final item = anime[index];
        return ListTile(
          leading: item.mainPicture?.medium != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: item.mainPicture!.medium!,
                    width: 48,
                    height: 68,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const SizedBox(
                      width: 48,
                      height: 68,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: 48, height: 68),
          title: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              if (item.mean != null) '⭐ ${item.mean}',
              if (item.numEpisodes != null) '${item.numEpisodes} eps',
              if (item.status != null) item.status,
            ].join(' · '),
          ),
          onTap: () => context.pushNamed(
            'animeDetail',
            pathParameters: {'id': '${item.id}'},
          ),
        );
      },
    );
  }
}

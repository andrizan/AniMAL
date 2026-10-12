import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/features/search/providers/search_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/shared/widgets/empty_view.dart';
import 'package:animal/shared/widgets/error_view.dart';
import 'package:animal/shared/widgets/section_header.dart';
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

  OutlineInputBorder _pillBorder(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final asyncAnime = _query.isEmpty
        ? ref.watch(animeRankingProvider)
        : ref.watch(animeSearchProvider(_query));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Back',
                    iconSize: 22,
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search anime',
                        prefixIcon: const Icon(Icons.search),
                        border: _pillBorder(scheme.outline, 1.5),
                        enabledBorder: _pillBorder(scheme.outline, 1.5),
                        focusedBorder: _pillBorder(scheme.primary, 2),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                tooltip: 'Clear search',
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
                ],
              ),
            ),
            Expanded(
              child: asyncAnime.when(
                skipLoadingOnReload: true,
                data: (list) =>
                    _AnimeListView(anime: list, showRanking: _query.isEmpty),
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
      ),
    );
  }
}

class _AnimeListView extends StatelessWidget {
  const _AnimeListView({required this.anime, required this.showRanking});

  final List<Anime> anime;
  final bool showRanking;

  @override
  Widget build(BuildContext context) {
    if (anime.isEmpty) {
      return const EmptyView(icon: Icons.search_off, message: 'No results');
    }

    final header = showRanking ? 1 : 0;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      itemCount: anime.length + header,
      itemBuilder: (context, index) {
        if (showRanking && index == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.page + AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.page + AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: SectionHeader('Top ranking', trailing: 'MyAnimeList'),
          );
        }
        final position = index - header;
        final item = anime[position];
        return AnimeCard(
          anime: item,
          rank: showRanking ? (item.rank ?? position + 1) : null,
        );
      },
    );
  }
}

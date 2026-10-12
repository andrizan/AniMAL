import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which works list a pager belongs to.
typedef WorksKey = ({AniListWorksSource source, int id});

/// What the works list of a character, staff member or studio shows right now.
class WorksPagerState {
  const WorksPagerState({
    required this.items,
    required this.hasMore,
    this.nextPage = 2,
    this.loadingMore = false,
    this.error,
  });

  final List<AniListMediaAppearance> items;

  /// Whether another page may exist after the ones loaded so far.
  final bool hasMore;

  /// The 1-based page [WorksPagerNotifier.loadMore] asks for next.
  final int nextPage;

  final bool loadingMore;

  /// The failure of the last [WorksPagerNotifier.loadMore], kept until a
  /// retry starts. The items already shown stay.
  final Object? error;

  /// Whether scrolling near the end should start a request on its own.
  /// It must not once a request failed, or a dead connection would loop.
  bool get canAutoLoad => hasMore && !loadingMore && error == null;

  WorksPagerState copyWith({
    List<AniListMediaAppearance>? items,
    bool? hasMore,
    int? nextPage,
    bool? loadingMore,
    Object? error,
    bool clearError = false,
  }) => WorksPagerState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    nextPage: nextPage ?? this.nextPage,
    loadingMore: loadingMore ?? this.loadingMore,
    error: clearError ? null : error ?? this.error,
  );
}

/// The paged works list of one character, staff member or studio.
///
/// It starts from the works stored with the detail the page already loaded:
/// the first page, plus every later page an earlier visit scrolled through.
/// The detail's cursor says where to continue, so nothing is fetched until the
/// user scrolls past what is stored. Further pages are requested one at a time
/// through [AniListClient.getWorksPage], which stores each one for next time.
final worksPagerProvider = NotifierProvider.autoDispose
    .family<WorksPagerNotifier, WorksPagerState, WorksKey>(
      WorksPagerNotifier.new,
    );

class WorksPagerNotifier extends Notifier<WorksPagerState> {
  WorksPagerNotifier(this.key);

  final WorksKey key;

  @override
  WorksPagerState build() {
    final (items, cursor) = _stored();
    return WorksPagerState(
      items: items,
      hasMore: cursor.hasMore,
      nextPage: cursor.nextPage,
    );
  }

  (List<AniListMediaAppearance>, AniListWorksCursor) _stored() =>
      switch (key.source) {
        AniListWorksSource.character => switch (ref
            .watch(anilistCharacterDetailProvider(key.id))
            .value) {
          final d? => (d.mediaAppearances, d.worksCursor),
          null => (const [], const AniListWorksCursor()),
        },
        AniListWorksSource.staff => switch (ref
            .watch(anilistStaffDetailProvider(key.id))
            .value) {
          final d? => (d.mediaWorks, d.worksCursor),
          null => (const [], const AniListWorksCursor()),
        },
        AniListWorksSource.studio => switch (ref
            .watch(anilistStudioDetailProvider(key.id))
            .value) {
          final d? => (d.mediaWorks, d.worksCursor),
          null => (const [], const AniListWorksCursor()),
        },
      };

  /// Loads the next page and appends it. Does nothing while a page is on its
  /// way or once the end was reached; after a failure it is the retry.
  Future<void> loadMore() async {
    final current = state;
    if (current.loadingMore || !current.hasMore) return;
    state = current.copyWith(loadingMore: true, clearError: true);

    try {
      final page = await ref
          .read(anilistApiProvider)
          .getWorksPage(key.source, key.id, current.nextPage);
      if (!ref.mounted) return;

      final seen = {for (final m in state.items) m.anilistId};
      final fresh = [
        for (final m in page.items)
          if (seen.add(m.anilistId)) m,
      ];
      state = state.copyWith(
        items: [...state.items, ...fresh],
        // An empty page ends the list, whatever AniList claims, so a
        // misbehaving server can never keep the scroll loading.
        hasMore: page.hasNextPage && page.items.isNotEmpty,
        nextPage: current.nextPage + 1,
        loadingMore: false,
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(loadingMore: false, error: e);
    }
  }
}

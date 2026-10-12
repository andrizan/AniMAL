import 'package:animal/shared/providers/airing_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Outcome of an explicit airing refresh, so the caller can word a snackbar.
enum AiringRefreshResult { refreshed, empty, failed, busy }

/// The snackbar text for a [result], or null when nothing needs saying.
String? airingRefreshMessage(AiringRefreshResult result) => switch (result) {
  AiringRefreshResult.empty => 'Airing schedule is empty, try again later',
  AiringRefreshResult.failed => 'Refresh failed, showing cached schedule',
  AiringRefreshResult.refreshed || AiringRefreshResult.busy => null,
};

/// Whether an explicit airing refresh is running. The home shell's header
/// button and the airing page's pull-to-refresh both go through
/// [AiringRefreshNotifier.refresh], so they share one spinner and never
/// start a second request.
final airingRefreshProvider = NotifierProvider<AiringRefreshNotifier, bool>(
  AiringRefreshNotifier.new,
);

class AiringRefreshNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<AiringRefreshResult> refresh() async {
    if (state) return AiringRefreshResult.busy;
    state = true;
    try {
      final week = await ref
          .read(airingRepositoryProvider)
          .refreshWeeklySchedule();
      return week.values.every((l) => l.isEmpty)
          ? AiringRefreshResult.empty
          : AiringRefreshResult.refreshed;
    } on Object {
      return AiringRefreshResult.failed;
    } finally {
      ref.invalidate(weeklyAiringProvider);
      state = false;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ticks every minute to keep airing countdowns and sorting live.
///
/// Providers that depend on `airingAt` should `ref.watch(clockProvider)` so
/// they rebuild when the clock advances and filtering/sorting stays accurate.
final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now().toUtc(),
  );
});

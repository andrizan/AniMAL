import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ticks every minute to keep airing countdowns and sorting live.
///
/// Only UI widgets and pure in-memory filtering should watch this.
/// Data providers must not watch it, otherwise every tick re-triggers
/// repository fetches and hammers the API.
final clockProvider = StreamProvider.autoDispose<DateTime>((ref) {
  return Stream.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now().toUtc(),
  );
});

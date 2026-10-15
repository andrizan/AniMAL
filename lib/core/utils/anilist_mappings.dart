/// MAL's `media_type` for an AniList media `format`, so AniList data can be
/// shown through the labels the app already has.
String? malMediaTypeOf(String? format) => switch (format) {
  null => null,
  'TV' || 'TV_SHORT' => 'tv',
  'MOVIE' => 'movie',
  'SPECIAL' => 'special',
  'OVA' => 'ova',
  'ONA' => 'ona',
  'MUSIC' => 'music',
  _ => format.toLowerCase(),
};

/// MAL's `status` for an AniList media `status`.
String? malStatusOf(String? status) => switch (status) {
  'RELEASING' => 'currently_airing',
  'FINISHED' || 'CANCELLED' => 'finished_airing',
  'NOT_YET_RELEASED' => 'not_yet_aired',
  _ => status,
};

/// AniList scores are out of 100; MAL's, and the app's, out of 10.
double? scoreOutOfTen(double? meanScore) =>
    meanScore == null ? null : meanScore / 10;

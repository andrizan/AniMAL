final class UserProfileEntity {
  const UserProfileEntity({
    required this.id,
    required this.name,
    this.picture,
    this.joinedAt,
    this.numItems,
    this.numEpisodes,
    this.daysWatched,
    this.meanScore,
    this.watching,
    this.completed,
    this.onHold,
    this.dropped,
    this.planToWatch,
  });

  final int id;
  final String name;
  final String? picture;
  final String? joinedAt;
  final int? numItems;
  final int? numEpisodes;
  final double? daysWatched;
  final double? meanScore;
  final int? watching;
  final int? completed;
  final int? onHold;
  final int? dropped;
  final int? planToWatch;
}

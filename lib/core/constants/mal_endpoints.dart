abstract final class MalEndpoints {
  static const animeList = '/users/@me/animelist';
  static const userInfo = '/users/@me';
  static const anime = '/anime';

  static String search() => anime;
  static String animeDetail(int id) => '$anime/$id';
  static String seasonal(int year, String season) =>
      '$anime/season/$year/$season';
  static String ranking() => '$anime/ranking';
  static String myListStatus(int id) => '$anime/$id/my_list_status';
}

abstract final class ApiConstants {
  static const notificationLeadMinutes = 15;
  static const cacheDurationMinutes = 15;
  static const anilistPageLimit = 5;
  static const anilistWeekPageLimit = 10;
  static const maxSeasonalResults = 500;
}

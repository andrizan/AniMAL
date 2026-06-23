import 'package:json_annotation/json_annotation.dart';

/// The four anime broadcast seasons used by MyAnimeList.
@JsonEnum(valueField: 'value')
enum Season {
  winter('winter'),
  spring('spring'),
  summer('summer'),
  fall('fall');

  const Season(this.value);

  /// Raw string sent to / received from the MAL API.
  final String value;

  /// Human-readable label for display in the UI.
  String get label => switch (this) {
        Season.winter => 'Winter',
        Season.spring => 'Spring',
        Season.summer => 'Summer',
        Season.fall => 'Fall',
      };

  /// Returns the [Season] that corresponds to the month of [date].
  ///
  /// Jan–Mar → winter, Apr–Jun → spring, Jul–Sep → summer,
  /// Oct–Dec → fall.
  static Season fromDate(DateTime date) {
    switch (date.month) {
      case 1:
      case 2:
      case 3:
        return Season.winter;
      case 4:
      case 5:
      case 6:
        return Season.spring;
      case 7:
      case 8:
      case 9:
        return Season.summer;
      default:
        return Season.fall;
    }
  }

  /// The MAL season year for [date].
  ///
  /// MAL labels each season by the calendar year it falls in, so
  /// this simply returns [DateTime.year].
  static int yearFromDate(DateTime date) => date.year;
}

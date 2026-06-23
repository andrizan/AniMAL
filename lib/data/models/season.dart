import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum Season {
  winter('winter'),
  spring('spring'),
  summer('summer'),
  fall('fall');

  const Season(this.value);

  final String value;

  String get label => switch (this) {
        Season.winter => 'Winter',
        Season.spring => 'Spring',
        Season.summer => 'Summer',
        Season.fall => 'Fall',
      };

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

  static int yearFromDate(DateTime date) => date.year;
}

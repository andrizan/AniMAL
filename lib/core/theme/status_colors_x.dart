import 'package:animal/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

extension StatusColorsX on BuildContext {
  StatusColors get statusColors =>
      Theme.of(this).extension<StatusColors>() ?? AppColors.lightStatus;
}

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const display = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 16,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const caption = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Utilitário para exibir SnackBars com as cores do sistema
class SnackBarUtils {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}


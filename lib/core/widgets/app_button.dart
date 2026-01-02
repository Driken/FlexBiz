import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Botão padronizado conforme especificação visual
/// Altura: 52px, Raio: 12px, Texto: 16px
enum AppButtonVariant { primary, secondary, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    Color backgroundColor;
    Color foregroundColor;
    Color? borderColor;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = AppColors.textInverse;
        borderColor = null;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = AppColors.cardBackground;
        foregroundColor = AppColors.textPrimary;
        borderColor = AppColors.borderDefault;
        break;
      case AppButtonVariant.danger:
        backgroundColor = AppColors.error;
        foregroundColor = AppColors.textInverse;
        borderColor = null;
        break;
    }

    Widget buttonContent = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textInverse),
            ),
          )
        : Text(
            text,
            style: AppTypography.body.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w500,
            ),
          );

    final button = Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDisabled ? backgroundColor.withOpacity(0.4) : backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: borderColor != null
            ? Border.all(color: isDisabled ? borderColor.withOpacity(0.4) : borderColor, width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Center(child: buttonContent),
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}


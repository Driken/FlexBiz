import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/theme/app_theme.dart';

class KPICard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color? color;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: cardColor, size: 24),
              Text(
                CurrencyUtils.format(value),
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cardColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Badge de status financeiro conforme especificação
/// Sempre exibe texto + cor (nunca apenas cor)
enum FinancialStatus { open, paid, late, canceled }

class StatusBadge extends StatelessWidget {
  final FinancialStatus status;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  String get _label {
    if (customLabel != null) return customLabel!;
    switch (status) {
      case FinancialStatus.open:
        return 'Em aberto';
      case FinancialStatus.paid:
        return 'Pago';
      case FinancialStatus.late:
        return 'Em atraso';
      case FinancialStatus.canceled:
        return 'Cancelado';
    }
  }

  Color get _color {
    switch (status) {
      case FinancialStatus.open:
        return AppColors.statusOpen;
      case FinancialStatus.paid:
        return AppColors.statusPaid;
      case FinancialStatus.late:
        return AppColors.statusLate;
      case FinancialStatus.canceled:
        return AppColors.statusCanceled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        _label,
        style: AppTypography.caption.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


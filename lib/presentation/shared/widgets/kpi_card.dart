import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/theme/app_colors.dart';

class KPICard extends StatefulWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color? color;
  final bool isHighlighted;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.isHighlighted = false,
  });

  @override
  State<KPICard> createState() => _KPICardState();
}

class _KPICardState extends State<KPICard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = widget.color ?? theme.colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              if (_isHovered)
                BoxShadow(
                  color: cardColor.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
            ],
            border: widget.isHighlighted
                ? Border(
                    left: BorderSide(
                      color: cardColor,
                      width: 4,
                    ),
                  )
                : null,
            gradient: widget.isHighlighted
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      cardColor.withOpacity(0.02),
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícone com badge circular
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: cardColor,
                        size: 24,
                      ),
                    ),
                    // Valor numérico (maior e mais destacado)
                    Flexible(
                      child: Text(
                        CurrencyUtils.format(widget.value),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: cardColor,
                          letterSpacing: -0.5,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Título com tipografia melhorada
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.1,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


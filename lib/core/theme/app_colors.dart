import 'package:flutter/material.dart';

/// Sistema de cores centralizado baseado na identidade visual do painel lateral
class AppColors {
  // Cor primária do sistema (azul do painel lateral)
  static const Color primary = Color(0xFF2196F3);
  
  // Cores semânticas para feedback e status
  static const Color success = Color(0xFF10B981); // Verde para sucesso
  static const Color error = Color(0xFFEF4444); // Vermelho para erros
  static const Color warning = Color(0xFFF59E0B); // Laranja para avisos
  static const Color info = Color(0xFF3B82F6); // Azul para informações
  
  // Cores especiais
  static const Color admin = Color(0xFF9333EA); // Roxo para admin
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF64B5F6);
  
  // Cores de texto
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  
  // Cores de fundo
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundHover = Color(0xFFF3F4F6);
  
  // Cores de borda
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);
  
  // Helper para obter cor primária do tema quando disponível
  static Color getPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }
  
  // Helper para obter cor de fundo do tema
  static Color getBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }
}


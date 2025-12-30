import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // IMPORTANTE: Substitua estas credenciais pelas do seu projeto Supabase
  // Para obter as credenciais:
  // 1. Acesse https://supabase.com
  // 2. Crie um projeto ou acesse um existente
  // 3. Vá em Settings > API
  // 4. Copie a "Project URL" e a "anon public" key

  // Credenciais obtidas automaticamente via MCP Supabase
  static const String supabaseUrl = 'https://jglwbbpcjkgglhftxeyn.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnbHdiYnBjamtnZ2xoZnR4ZXluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwOTEzNzQsImV4cCI6MjA4MjY2NzM3NH0.EM-m_V_QgF_y8sMfRCsnGyBEyPtJaFWBu_uTQjdDEQ4';

  static Future<void> initialize() async {
    // Verifica se as credenciais foram configuradas
    if (supabaseUrl == 'YOUR_SUPABASE_URL' ||
        supabaseAnonKey == 'YOUR_SUPABASE_ANON_KEY') {
      throw Exception('⚠️ Supabase não configurado!\n\n'
          'Por favor, configure as credenciais do Supabase em:\n'
          'lib/core/config/supabase_config.dart\n\n'
          'Substitua YOUR_SUPABASE_URL e YOUR_SUPABASE_ANON_KEY\n'
          'pelas credenciais do seu projeto Supabase.');
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } catch (e) {
      throw Exception('Erro ao inicializar Supabase: $e\n\n'
          'Verifique se:\n'
          '1. A URL do Supabase está correta\n'
          '2. A chave anon está correta\n'
          '3. O projeto Supabase está ativo');
    }
  }

  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      throw Exception('Supabase não foi inicializado. Certifique-se de chamar '
          'SupabaseConfig.initialize() antes de usar o cliente.');
    }
  }
}

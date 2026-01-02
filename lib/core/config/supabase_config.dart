import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Valores padrão (fallback) - usar apenas em desenvolvimento local
  // Em produção, sempre usar variáveis de ambiente via --dart-define
  static const String _defaultSupabaseUrl =
      'https://jglwbbpcjkgglhftxeyn.supabase.co';
  static const String _defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnbHdiYnBjamtnZ2xoZnR4ZXluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwOTEzNzQsImV4cCI6MjA4MjY2NzM3NH0.EM-m_V_QgF_y8sMfRCsnGyBEyPtJaFWBu_uTQjdDEQ4';
  static const String _defaultSupabaseServiceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnbHdiYnBjamtnZ2xoZnR4ZXluIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzA5MTM3NCwiZXhwIjoyMDgyNjY3Mzc0fQ.MKyQQOGntJ90No-z8iFINmuvlC0itkztmbseQjGkF6g'; // Obtenha em Settings > API > service_role key (secret)

  // Lê variáveis de ambiente definidas via --dart-define ou --dart-define-from-file
  // Essas variáveis são passadas pelo Dockerfile durante o build
  static String get supabaseUrl {
    const url = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: _defaultSupabaseUrl,
    );
    if (url.isEmpty) {
      throw Exception(
        'SUPABASE_URL não está definida. '
        'Defina via --dart-define=SUPABASE_URL=... ou arquivo .env',
      );
    }
    return url;
  }

  static String get supabaseAnonKey {
    const key = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: _defaultSupabaseAnonKey,
    );
    if (key.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY não está definida. '
        'Defina via --dart-define=SUPABASE_ANON_KEY=... ou arquivo .env',
      );
    }
    return key;
  }

  // IMPORTANTE: A service role key deve ser obtida do painel do Supabase
  // Settings > API > service_role key (secret)
  // Por segurança, NUNCA commitar esta chave no repositório
  // Em produção, sempre usar variáveis de ambiente via --dart-define
  static String get supabaseServiceRoleKey {
    const key = String.fromEnvironment(
      'SUPABASE_SERVICE_ROLE_KEY',
      defaultValue: _defaultSupabaseServiceRoleKey,
    );
    if (key.isEmpty || key == 'YOUR_SUPABASE_SERVICE_ROLE_KEY') {
      throw Exception(
        'SUPABASE_SERVICE_ROLE_KEY não está definida. '
        'Defina via --dart-define=SUPABASE_SERVICE_ROLE_KEY=... ou arquivo .env. '
        'Obtenha a chave em Settings > API > service_role key (secret)',
      );
    }
    return key;
  }

  static SupabaseClient? _adminClient;

  static Future<void> initialize() async {
    // Debug: log das configurações (apenas em modo debug, sem expor chaves completas)
    if (kDebugMode) {
      print('🔧 SupabaseConfig.initialize()');
      print('   URL: ${supabaseUrl}');
      print('   Anon Key: ${supabaseAnonKey.substring(0, 20)}...');
      // Verificar se está usando valores padrão ou variáveis de ambiente
      final usingEnvUrl = supabaseUrl != _defaultSupabaseUrl;
      final usingEnvKey = supabaseAnonKey != _defaultSupabaseAnonKey;
      print('   Using env vars: URL=${usingEnvUrl}, Key=${usingEnvKey}');
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

  /// Cliente com service role key para operações administrativas
  /// Use apenas para operações que requerem privilégios de admin
  static SupabaseClient get adminClient {
    _adminClient ??= SupabaseClient(supabaseUrl, supabaseServiceRoleKey);
    return _adminClient!;
  }
}

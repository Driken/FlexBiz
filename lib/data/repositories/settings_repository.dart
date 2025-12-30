import '../models/settings_model.dart';
import '../../core/config/supabase_config.dart';

class SettingsRepository {
  final _supabase = SupabaseConfig.client;

  /// Busca as configurações de uma empresa
  Future<SystemSettings> getSettings(String companyId) async {
    try {
      final response = await _supabase
          .from('companies')
          .select('settings')
          .eq('id', companyId)
          .single();

      final settingsJson = response['settings'] as Map<String, dynamic>? ?? {};
      return SystemSettings.fromJson(settingsJson);
    } catch (e) {
      // Se não encontrar, retorna configurações padrão
      return SystemSettings();
    }
  }

  /// Salva as configurações de uma empresa
  Future<void> saveSettings(String companyId, SystemSettings settings) async {
    await _supabase
        .from('companies')
        .update({
          'settings': settings.toJson(),
        })
        .eq('id', companyId);
  }

  /// Atualiza uma seção específica das configurações
  Future<void> updateSettingsSection(
    String companyId,
    String section,
    Map<String, dynamic> sectionData,
  ) async {
    final currentSettings = await getSettings(companyId);
    final currentJson = currentSettings.toJson();
    currentJson[section] = sectionData;
    
    await _supabase
        .from('companies')
        .update({
          'settings': currentJson,
        })
        .eq('id', companyId);
  }

  /// Reseta as configurações para os valores padrão
  Future<void> resetToDefaults(String companyId) async {
    final defaultSettings = SystemSettings();
    await saveSettings(companyId, defaultSettings);
  }
}


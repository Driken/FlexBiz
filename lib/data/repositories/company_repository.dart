import '../models/company_model.dart';
import '../../core/config/supabase_config.dart';

class CompanyRepository {
  final _supabase = SupabaseConfig.client;

  Future<CompanyModel> getCompany(String companyId) async {
    final response = await _supabase
        .from('companies')
        .select()
        .eq('id', companyId)
        .single();

    return CompanyModel.fromJson(response);
  }

  /// Cria uma empresa (apenas para super admins)
  Future<CompanyModel> createCompany({
    required String name,
    String? document,
  }) async {
    final response = await _supabase
        .from('companies')
        .insert({
          'name': name,
          'document': document,
        })
        .select()
        .single();

    return CompanyModel.fromJson(response);
  }

  /// Exclui uma empresa (apenas para super admins)
  Future<void> deleteCompany(String id) async {
    await _supabase.from('companies').delete().eq('id', id);
  }
}


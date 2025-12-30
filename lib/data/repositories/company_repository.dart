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
}


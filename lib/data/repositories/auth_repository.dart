import '../models/profile_model.dart';
import '../../core/config/supabase_config.dart';

class AuthRepository {
  final _supabase = SupabaseConfig.client;

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String companyName,
    String? companyDocument,
  }) async {
    // 1. Criar usuário no Supabase Auth
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Falha ao criar usuário');
    }

    final userId = authResponse.user!.id;

    // 2. Criar empresa
    final companyResponse = await _supabase
        .from('companies')
        .insert({
          'name': companyName,
          'document': companyDocument,
        })
        .select()
        .single();

    final companyId = companyResponse['id'] as String;

    // 3. Criar perfil vinculando user → company
    await _supabase.from('profiles').insert({
      'id': userId,
      'company_id': companyId,
      'name': name,
      'role': 'owner',
    });

    return {
      'user': authResponse.user,
      'company_id': companyId,
    };
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<ProfileModel?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }
}


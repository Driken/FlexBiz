import '../models/profile_model.dart';
import '../../core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importar apenas quando necessário para evitar dependência circular
// A referência a SupabaseConfig.adminClient será resolvida em runtime

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

  /// Cria um usuário pelo admin vinculado a uma empresa existente
  Future<Map<String, dynamic>> createUserByAdmin({
    required String email,
    required String password,
    required String name,
    required String companyId,
    String role = 'user',
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

    // 2. Criar perfil vinculando user → company (incluindo email para fácil acesso)
    await _supabase.from('profiles').insert({
      'id': userId,
      'company_id': companyId,
      'name': name,
      'role': role,
      'email': email, // Armazenar email no perfil para fácil acesso
    });

    return {
      'user': authResponse.user,
      'company_id': companyId,
    };
  }

  /// Atualiza um perfil de usuário
  Future<ProfileModel> updateUserProfile({
    required String userId,
    required String name,
    required String companyId,
    required String role,
  }) async {
    final response = await _supabase
        .from('profiles')
        .update({
          'name': name,
          'company_id': companyId,
          'role': role,
        })
        .eq('id', userId)
        .select()
        .single();

    return ProfileModel.fromJson(response);
  }

  /// Deleta um usuário (perfil)
  /// Nota: A exclusão do usuário do auth.users requer permissões de admin
  /// e deve ser feita via Edge Function ou Admin API do Supabase
  Future<void> deleteUser(String userId) async {
    // Deletar perfil (o usuário do auth permanecerá, mas sem acesso ao sistema)
    await _supabase.from('profiles').delete().eq('id', userId);
  }

  /// Busca um perfil por ID
  Future<ProfileModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Busca o email do usuário
  /// Primeiro tenta buscar do perfil (mais rápido), depois tenta via admin API
  Future<String?> getUserEmail(String userId) async {
    try {
      // 1. Tentar buscar do perfil primeiro (se foi armazenado)
      try {
        final profile = await _supabase
            .from('profiles')
            .select('email')
            .eq('id', userId)
            .maybeSingle();
        
        if (profile != null && profile['email'] != null && profile['email'].toString().isNotEmpty) {
          return profile['email'] as String;
        }
      } catch (e) {
        print('Erro ao buscar email do perfil: $e');
      }
      
      // 2. Se não estiver no perfil, buscar via admin API usando service_role
      try {
        final adminClient = SupabaseConfig.adminClient;
        final user = await adminClient.auth.admin.getUserById(userId);
        final email = user.user?.email;
        
        // Se encontrou o email, atualizar o perfil para próximo acesso
        if (email != null && email.isNotEmpty) {
          try {
            await _supabase
                .from('profiles')
                .update({'email': email})
                .eq('id', userId);
          } catch (e) {
            print('Erro ao atualizar email no perfil: $e');
          }
        }
        
        return email;
      } catch (e) {
        print('Erro ao buscar email via admin API: $e');
      }
      
      return null;
    } catch (e) {
      print('Erro geral ao buscar email: $e');
      return null;
    }
  }

  /// Atualiza a senha de um usuário
  /// Usa adminClient com service_role para ter permissões totais
  Future<void> updateUserPassword(String userId, String newPassword) async {
    try {
      final adminClient = SupabaseConfig.adminClient;
      await adminClient.auth.admin.updateUserById(
        userId,
        attributes: AdminUserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Não foi possível atualizar a senha. Verifique as permissões: $e');
    }
  }
}


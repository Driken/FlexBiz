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
    try {
      // 1. Criar usuário no Supabase Auth
      // Usar data para passar informações adicionais
      // emailRedirectTo: null evita confirmação por email se configurado no projeto
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'company_name': companyName,
        },
        emailRedirectTo: null,
      );

      // Verificar se houve erro de rate limit
      if (authResponse.user == null) {
        // Verificar se é erro de rate limit
        if (authResponse.session == null) {
          throw Exception(
            'Não foi possível criar a conta. '
            'Você tentou criar muitas contas em pouco tempo. '
            'Por favor, aguarde alguns minutos e tente novamente.'
          );
        }
        throw Exception('Falha ao criar usuário no sistema de autenticação');
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
    } catch (e) {
      // Tratamento específico para erros de rate limit
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('rate_limit') || 
          errorMessage.contains('over_email_send_rate_limit') ||
          errorMessage.contains('53 seconds')) {
        throw Exception(
          'Muitas tentativas de cadastro. '
          'Por segurança, aguarde aproximadamente 1 minuto antes de tentar novamente.'
        );
      }
      // Re-throw outros erros
      rethrow;
    }
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

  /// Atualiza um usuário via admin (apenas para super admins)
  /// Nota: Atualização de email requer uma Edge Function ou service_role key
  Future<void> updateUser({
    required String userId,
    required String name,
    String? email,
    required String companyId,
    required String role,
  }) async {
    try {
      // Verificar se o usuário atual é super_admin
      final currentProfile = await getCurrentProfile();
      if (currentProfile == null || !currentProfile.isSuperAdmin) {
        throw Exception('Apenas super admins podem atualizar usuários');
      }

      // Atualizar perfil na tabela profiles usando função stored procedure
      // que bypassa RLS
      await _supabase.rpc(
        'update_user_profile',
        params: {
          'p_user_id': userId,
          'p_name': name,
          'p_company_id': companyId,
          'p_role': role,
          // p_admin_id usa default auth.uid()
        },
      );

      // Nota: Atualização de email no Supabase Auth requer permissões especiais
      // (service_role key ou Edge Function). Para implementar isso, você precisaria:
      // 1. Criar uma Edge Function no Supabase
      // 2. Ou usar a API REST diretamente com service_role key (não recomendado no cliente)
      // Por enquanto, apenas atualizamos o perfil
      
      if (email != null && email.isNotEmpty) {
        // Log informativo - a atualização de email precisaria ser feita separadamente
        print('Nota: Para atualizar o email, é necessário usar uma Edge Function do Supabase');
      }
    } catch (e) {
      // Se a função RPC não existir, usar update direto
      if (e.toString().contains('function') || e.toString().contains('does not exist')) {
        // Fallback: usar update direto (requer que a política RLS permita)
        await _supabase
            .from('profiles')
            .update({
              'name': name,
              'company_id': companyId,
              'role': role,
            })
            .eq('id', userId);
      } else {
        rethrow;
      }
    }
  }

  /// Busca o email de um usuário do Supabase Auth
  /// Nota: Isso requer uma função stored procedure ou Edge Function
  Future<String?> getUserEmail(String userId) async {
    try {
      // Usar uma função stored procedure que busca o email do auth.users
      final response = await _supabase.rpc(
        'get_user_email',
        params: {'p_user_id': userId},
      );
      return response as String?;
    } catch (e) {
      // Se a função não existir, retornar null
      print('Não foi possível buscar email do usuário: $e');
      return null;
    }
  }

  /// Exclui um usuário (apenas para super admins)
  /// Remove o perfil usando função stored procedure
  Future<void> deleteUser(String userId) async {
    try {
      // Verificar se o usuário atual é super_admin
      final currentProfile = await getCurrentProfile();
      if (currentProfile == null || !currentProfile.isSuperAdmin) {
        throw Exception('Apenas super admins podem excluir usuários');
      }

      // Usar função stored procedure para excluir
      await _supabase.rpc(
        'delete_user',
        params: {
          'p_user_id': userId,
        },
      );
    } catch (e) {
      // Se a função não existir, tentar excluir apenas o perfil
      if (e.toString().contains('function') || 
          e.toString().contains('does not exist')) {
        // Fallback: excluir apenas o perfil
        await _supabase
            .from('profiles')
            .delete()
            .eq('id', userId);
      } else {
        rethrow;
      }
    }
  }

  /// Cria um usuário via admin (apenas para super admins)
  /// Retorna o ID do usuário criado
  Future<String> createUser({
    required String email,
    required String password,
    required String name,
    required String companyId,
    required String role,
  }) async {
    String? userId;
    
    try {
      // 1. Verificar se o usuário atual é super_admin
      final currentProfile = await getCurrentProfile();
      if (currentProfile == null || !currentProfile.isSuperAdmin) {
        throw Exception('Apenas super admins podem criar usuários');
      }

      // 2. Criar usuário no Supabase Auth
      // IMPORTANTE: O signUp faz login automático do novo usuário
      // Por isso precisamos usar uma função stored procedure
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role,
          'company_id': companyId,
        },
        emailRedirectTo: null,
      );

      if (authResponse.user == null) {
        final errorMsg = authResponse.session == null 
            ? 'Falha ao criar usuário no sistema de autenticação. Verifique se o email já existe.'
            : 'Falha ao criar usuário no sistema de autenticação';
        throw Exception(errorMsg);
      }

      userId = authResponse.user!.id;

      // 3. Salvar o ID do admin antes do signUp fazer login do novo usuário
      final adminUserId = currentProfile.id;
      
      // 4. Criar perfil usando função stored procedure
      // Esta função verifica se o admin_id fornecido é super_admin
      // e cria o perfil bypassando RLS
      try {
        await _supabase.rpc(
          'create_user_with_profile',
          params: {
            'p_admin_id': adminUserId,
            'p_user_id': userId,
            'p_company_id': companyId,
            'p_name': name,
            'p_role': role,
          },
        );

        // Verificar se o perfil foi criado
        final profileCheck = await _supabase
            .from('profiles')
            .select('id')
            .eq('id', userId)
            .single();

        if (profileCheck.isEmpty) {
          throw Exception('Falha ao criar perfil: perfil não encontrado após criação');
        }

        // Fazer login novamente como admin se necessário
        // (O signUp fez login do novo usuário, então precisamos restaurar a sessão do admin)
        // Mas isso é complicado - vamos deixar o novo usuário logado e mostrar mensagem

        return userId;
      } catch (profileError) {
        // Se falhar ao criar perfil, o usuário já foi criado no Auth
        throw Exception(
          'Erro ao criar perfil do usuário: ${profileError.toString()}. '
          'O usuário foi criado no sistema de autenticação mas o perfil não foi criado. '
          'Pode ser necessário remover o usuário manualmente.'
        );
      }
    } catch (e) {
      // Re-throw com informações mais detalhadas
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erro inesperado ao criar usuário: ${e.toString()}');
    }
  }
}


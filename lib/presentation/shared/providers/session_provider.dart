import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flexbiz/data/models/profile_model.dart';
import 'package:flexbiz/data/repositories/auth_repository.dart';
import 'package:flexbiz/core/config/supabase_config.dart';

class Session {
  final String userId;
  final String companyId;
  final String role;
  final ProfileModel profile;

  Session({
    required this.userId,
    required this.companyId,
    required this.role,
    required this.profile,
  });
}

final sessionProvider = StreamProvider<Session?>((ref) {
  final supabase = SupabaseConfig.client;
  final authRepo = AuthRepository();

  // Escutar mudanças no estado de autenticação
  return supabase.auth.onAuthStateChange.asyncMap((data) async {
    final user = data.session?.user;
    
    // Se não houver usuário, retornar null imediatamente
    if (user == null) {
      return null;
    }

    try {
      // Tentar buscar perfil com retry em caso de erro temporário
      ProfileModel? profile;
      for (int i = 0; i < 3; i++) {
        try {
          profile = await authRepo.getCurrentProfile();
          if (profile != null) break;
        } catch (e) {
          if (i < 2) {
            // Aguardar um pouco antes de tentar novamente
            await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
            continue;
          }
          rethrow;
        }
      }
      
      if (profile == null) return null;

      return Session(
        userId: user.id,
        companyId: profile.companyId,
        role: profile.role,
        profile: profile,
      );
    } catch (e) {
      // Se houver erro ao buscar perfil, retornar null
      // Mas apenas se realmente não houver usuário autenticado
      return null;
    }
  });
});


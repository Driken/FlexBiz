import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/config/supabase_config.dart';

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

  return supabase.auth.onAuthStateChange.asyncMap((data) async {
    final user = data.session?.user;
    if (user == null) return null;

    final profile = await authRepo.getCurrentProfile();
    if (profile == null) return null;

    return Session(
      userId: user.id,
      companyId: profile.companyId,
      role: profile.role,
      profile: profile,
    );
  });
});


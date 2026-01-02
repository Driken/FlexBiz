import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../shared/providers/session_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(ref),
);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final AuthRepository _authRepository;

  AuthNotifier(this._ref)
      : _authRepository = _ref.read(authRepositoryProvider),
        super(const AsyncValue.data(null));

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String companyName,
    String? companyDocument,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signUp(
        email: email,
        password: password,
        name: name,
        companyName: companyName,
        companyDocument: companyDocument,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signIn(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      // Fazer logout primeiro
      await _authRepository.signOut();
      
      // Aguardar um pouco para garantir que o Supabase processe o logout
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Invalidar o sessionProvider após o signOut para garantir atualização
      _ref.invalidate(sessionProvider);
      
      // Aguardar mais um pouco para garantir que o stream seja atualizado
      await Future.delayed(const Duration(milliseconds: 100));
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}


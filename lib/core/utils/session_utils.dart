import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/shared/providers/session_provider.dart';

/// Obtém a sessão de forma segura, aguardando se necessário
/// Retorna null se a sessão não estiver disponível após tentativas
Future<Session?> getSessionSafely(WidgetRef ref) async {
  // Tentar obter imediatamente
  var sessionAsync = ref.read(sessionProvider);
  
  if (sessionAsync.hasValue && sessionAsync.value != null) {
    return sessionAsync.value;
  }
  
  // Se está em loading ou não tem valor, aguardar um pouco e tentar novamente
  for (int i = 0; i < 5; i++) {
    await Future.delayed(const Duration(milliseconds: 100));
    sessionAsync = ref.read(sessionProvider);
    if (sessionAsync.hasValue && sessionAsync.value != null) {
      return sessionAsync.value;
    }
    if (sessionAsync.hasError) {
      break;
    }
  }
  
  return null;
}


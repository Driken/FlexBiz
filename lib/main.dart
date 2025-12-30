import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/shared/providers/session_provider.dart';
import 'presentation/dashboard/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    // Se houver erro na inicialização, mostra uma tela de erro
    runApp(
      MaterialApp(
        title: 'FlexBiz - Erro de Configuração',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Erro de Configuração',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);
    
    return MaterialApp(
      title: 'FlexBiz',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: sessionAsync.when(
        data: (session) {
          if (session != null) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Text('Erro: $error'),
          ),
        ),
      ),
    );
  }
}


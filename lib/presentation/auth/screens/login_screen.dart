import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erro ao fazer login';
        
        // Mensagens de erro mais amigáveis
        final errorString = e.toString();
        if (errorString.contains('404') || errorString.contains('Not Found')) {
          errorMessage = 'Erro: Supabase não configurado ou URL inválida.\n'
              'Verifique as credenciais em lib/core/config/supabase_config.dart';
        } else if (errorString.contains('Invalid login credentials') || 
                   errorString.contains('Email not confirmed')) {
          errorMessage = 'Email ou senha incorretos';
        } else if (errorString.contains('Network')) {
          errorMessage = 'Erro de conexão. Verifique sua internet';
        } else {
          errorMessage = 'Erro: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _fillTestCredentials() {
    setState(() {
      _emailController.text = 'teste@flexbiz.com';
      _passwordController.text = '123456';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.business_center,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'FlexBiz',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestão para Pequenos Negócios',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite seu e-mail';
                      }
                      if (!value.contains('@')) {
                        return 'E-mail inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite sua senha';
                      }
                      if (value.length < 6) {
                        return 'Senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  if (kDebugMode)
                    OutlinedButton.icon(
                      onPressed: _fillTestCredentials,
                      icon: const Icon(Icons.bug_report, size: 18),
                      label: const Text('Preencher Conta Teste'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  if (kDebugMode) const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text('Não tem conta? Cadastre-se'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


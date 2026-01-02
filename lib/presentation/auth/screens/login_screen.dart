import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_button.dart';
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
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erro ao fazer login';
        
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
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.business_center,
                      size: 80,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'FlexBiz',
                      style: AppTypography.title,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Gestão para Pequenos Negócios',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppInput(
                      label: 'E-mail',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email),
                      errorText: _emailError,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          setState(() {
                            _emailError = 'Digite seu e-mail';
                          });
                          return '';
                        }
                        if (!value.contains('@')) {
                          setState(() {
                            _emailError = 'E-mail inválido';
                          });
                          return '';
                        }
                        setState(() {
                          _emailError = null;
                        });
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.blockSpacing),
                    AppInput(
                      label: 'Senha',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
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
                      errorText: _passwordError,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          setState(() {
                            _passwordError = 'Digite sua senha';
                          });
                          return '';
                        }
                        if (value.length < 6) {
                          setState(() {
                            _passwordError = 'Senha deve ter pelo menos 6 caracteres';
                          });
                          return '';
                        }
                        setState(() {
                          _passwordError = null;
                        });
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    if (kDebugMode)
                      AppButton(
                        text: 'Preencher Conta Teste',
                        variant: AppButtonVariant.secondary,
                        onPressed: _fillTestCredentials,
                      ),
                    if (kDebugMode) const SizedBox(height: AppSpacing.blockSpacing),
                    AppButton(
                      text: 'Entrar',
                      onPressed: authState.isLoading ? null : _handleLogin,
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: AppSpacing.blockSpacing),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Não tem conta? Cadastre-se',
                        style: AppTypography.body.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


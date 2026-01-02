import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyDocumentController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _companyNameError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _companyDocumentController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _companyNameError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            companyName: _companyNameController.text.trim(),
            companyDocument: _companyDocumentController.text.trim().isEmpty
                ? null
                : _companyDocumentController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar conta: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Criar Conta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Dados Pessoais',
                    style: AppTypography.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.blockSpacing),
                  AppInput(
                    label: 'Seu Nome',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person),
                    errorText: _nameError,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() {
                          _nameError = 'Digite seu nome';
                        });
                        return '';
                      }
                      setState(() {
                        _nameError = null;
                      });
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.blockSpacing),
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
                  const SizedBox(height: AppSpacing.blockSpacing),
                  AppInput(
                    label: 'Confirmar Senha',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    errorText: _confirmPasswordError,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() {
                          _confirmPasswordError = 'Confirme sua senha';
                        });
                        return '';
                      }
                      if (value != _passwordController.text) {
                        setState(() {
                          _confirmPasswordError = 'Senhas não coincidem';
                        });
                        return '';
                      }
                      setState(() {
                        _confirmPasswordError = null;
                      });
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Dados da Empresa',
                    style: AppTypography.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.blockSpacing),
                  AppInput(
                    label: 'Nome da Empresa',
                    controller: _companyNameController,
                    prefixIcon: const Icon(Icons.business),
                    errorText: _companyNameError,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() {
                          _companyNameError = 'Digite o nome da empresa';
                        });
                        return '';
                      }
                      setState(() {
                        _companyNameError = null;
                      });
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.blockSpacing),
                  AppInput(
                    label: 'CNPJ/CPF (opcional)',
                    controller: _companyDocumentController,
                    prefixIcon: const Icon(Icons.badge),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    text: 'Criar Conta',
                    onPressed: authState.isLoading ? null : _handleSignUp,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: AppSpacing.blockSpacing),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Já tem conta? Faça login',
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
    );
  }
}


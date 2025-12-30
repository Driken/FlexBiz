import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erro ao criar conta';
        String errorDetails = e.toString();
        
        // Tratamento específico para rate limit
        if (errorDetails.contains('rate_limit') || 
            errorDetails.contains('over_email_send_rate_limit') ||
            errorDetails.contains('53 seconds')) {
          errorMessage = 'Limite de tentativas excedido';
          errorDetails = 'Por segurança, você só pode solicitar o cadastro novamente após cerca de 1 minuto. '
              'Aguarde um momento e tente novamente.';
        } else if (errorDetails.contains('User already registered')) {
          errorMessage = 'Email já cadastrado';
          errorDetails = 'Este email já está cadastrado no sistema. Tente fazer login.';
        } else if (errorDetails.contains('Invalid email')) {
          errorMessage = 'Email inválido';
          errorDetails = 'Por favor, verifique se o email está correto.';
        } else if (errorDetails.contains('Password')) {
          errorMessage = 'Senha inválida';
          errorDetails = 'A senha deve ter pelo menos 6 caracteres.';
        } else if (errorDetails.contains('infinite recursion') || 
                   errorDetails.contains('42P17')) {
          errorMessage = 'Erro de configuração';
          errorDetails = 'Ocorreu um erro na configuração do sistema. '
              'Por favor, entre em contato com o suporte técnico.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  errorDetails,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Dados Pessoais',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Seu Nome',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite seu nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
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
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirme sua senha';
                    }
                    if (value != _passwordController.text) {
                      return 'Senhas não coincidem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Dados da Empresa',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Empresa *',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite o nome da empresa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _companyDocumentController,
                  decoration: const InputDecoration(
                    labelText: 'CNPJ/CPF (opcional)',
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleSignUp,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Criar Conta'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Já tem conta? Faça login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


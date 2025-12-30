import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../shared/widgets/modal_form_dialog.dart';

class UserFormDialog extends ConsumerStatefulWidget {
  const UserFormDialog({super.key});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      builder: (context) => const UserFormDialog(),
    );
  }
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  
  String? _selectedCompanyId;
  String _selectedRole = 'user';
  List<Map<String, dynamic>> _companies = [];

  final _authRepository = AuthRepository();
  final _supabase = SupabaseConfig.client;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .order('name', ascending: true);
      if (mounted) {
        setState(() {
          _companies = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar empresas: $e')),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma empresa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepository.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        companyId: _selectedCompanyId!,
        role: _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário criado com sucesso!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar usuário: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalFormDialog(
      title: 'Cadastrar Usuário',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o email';
                }
                if (!value.contains('@')) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Senha *',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite a senha';
                }
                if (value.length < 6) {
                  return 'Senha deve ter no mínimo 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirmar Senha *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirme a senha';
                }
                if (value != _passwordController.text) {
                  return 'Senhas não coincidem';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCompanyId,
              decoration: const InputDecoration(
                labelText: 'Empresa *',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _companies.map((company) {
                return DropdownMenuItem<String>(
                  value: company['id'] as String,
                  child: Text(company['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCompanyId = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecione uma empresa';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Nível de Acesso *',
                prefixIcon: Icon(Icons.admin_panel_settings),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Usuário')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                DropdownMenuItem(value: 'owner', child: Text('Proprietário')),
                DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Cadastrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


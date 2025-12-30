import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../shared/widgets/modal_form_dialog.dart';

class UserEditDialog extends ConsumerStatefulWidget {
  final String userId;
  final String currentName;
  final String? currentEmail;
  final String currentCompanyId;
  final String currentRole;

  const UserEditDialog({
    super.key,
    required this.userId,
    required this.currentName,
    this.currentEmail,
    required this.currentCompanyId,
    required this.currentRole,
  });

  @override
  ConsumerState<UserEditDialog> createState() => _UserEditDialogState();

  static Future<bool?> show(
    BuildContext context, {
    required String userId,
    required String currentName,
    String? currentEmail,
    required String currentCompanyId,
    required String currentRole,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      builder: (context) => UserEditDialog(
        userId: userId,
        currentName: currentName,
        currentEmail: currentEmail,
        currentCompanyId: currentCompanyId,
        currentRole: currentRole,
      ),
    );
  }
}

class _UserEditDialogState extends ConsumerState<UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  
  String? _selectedCompanyId;
  String _selectedRole = 'user';
  List<Map<String, dynamic>> _companies = [];

  final _authRepository = AuthRepository();
  final _supabase = SupabaseConfig.client;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _emailController.text = widget.currentEmail ?? '';
    _selectedCompanyId = widget.currentCompanyId;
    _selectedRole = widget.currentRole;
    _loadCompanies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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
      await _authRepository.updateUser(
        userId: widget.userId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        companyId: _selectedCompanyId!,
        role: _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário atualizado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar usuário: ${e.toString()}'),
            backgroundColor: Colors.red,
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
      title: 'Editar Usuário',
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
                labelText: 'Email (opcional - requer permissões especiais)',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                helperText: 'Nota: Alterar email requer permissões de administrador do Supabase',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && !value.contains('@')) {
                  return 'Email inválido';
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
                        : const Text('Salvar Alterações'),
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


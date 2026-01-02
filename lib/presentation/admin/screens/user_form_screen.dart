import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/config/supabase_config.dart';
import '../../../data/repositories/auth_repository.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? profile;

  const UserFormScreen({super.key, this.profile});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isLoadingCompanies = true;
  bool _isLoadingEmail = false;

  final _supabase = SupabaseConfig.client;
  List<Map<String, dynamic>> _companies = [];
  String? _selectedCompanyId;
  String _selectedRole = 'user';

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _companyError;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _nameController.text = widget.profile!['name'] ?? '';
      _selectedCompanyId = widget.profile!['company_id'];
      _selectedRole = widget.profile!['role'] ?? 'user';
      _loadUserEmail();
    }
    _loadCompanies();
  }

  Future<void> _loadUserEmail() async {
    if (widget.profile == null) return;

    setState(() {
      _isLoadingEmail = true;
    });

    try {
      String? email = widget.profile!['email'];

      if (email == null || email.isEmpty || email == 'null') {
        final authRepo = AuthRepository();
        email = await authRepo.getUserEmail(widget.profile!['id']);
      }

      if (mounted) {
        if (email != null && email.isNotEmpty && email != 'null') {
          _emailController.text = email;
        } else {
          _emailController.text = '';
        }
      }
    } catch (e) {
      print('Erro ao buscar email: $e');
      if (mounted) {
        _emailController.text = '';
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEmail = false;
        });
      }
    }
  }

  Future<void> _loadCompanies() async {
    setState(() => _isLoadingCompanies = true);
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .order('name');
      setState(() {
        _companies = List<Map<String, dynamic>>.from(response);
        _isLoadingCompanies = false;

        if (widget.profile != null && _selectedCompanyId != null) {
          final companyExists = _companies.any((c) => c['id'] == _selectedCompanyId);
          if (!companyExists && _companies.isNotEmpty) {
            _selectedCompanyId = _companies.first['id'];
          }
        } else if (_companies.isNotEmpty && _selectedCompanyId == null) {
          _selectedCompanyId = _companies.first['id'];
        }
      });
    } catch (e) {
      setState(() => _isLoadingCompanies = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar empresas: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _companyError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCompanyId == null) {
      setState(() {
        _companyError = 'Selecione uma empresa';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepo = AuthRepository();

      if (widget.profile == null) {
        await authRepo.createUserByAdmin(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          companyId: _selectedCompanyId!,
          role: _selectedRole,
        );
      } else {
        await authRepo.updateUserProfile(
          userId: widget.profile!['id'],
          name: _nameController.text.trim(),
          companyId: _selectedCompanyId!,
          role: _selectedRole,
        );

        if (_passwordController.text.isNotEmpty) {
          await authRepo.updateUserPassword(
            widget.profile!['id'],
            _passwordController.text,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.profile == null
                ? 'Usuário criado com sucesso!'
                : 'Usuário atualizado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.profile == null ? 'Novo Usuário' : 'Editar Usuário'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width < 600 ? 420 : 600,
              ),
              child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppInput(
                    label: 'Nome do Usuário',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person),
                    hint: 'Digite o nome completo',
                    errorText: _nameError,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() {
                          _nameError = 'Digite o nome do usuário';
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
                  _isLoadingEmail && widget.profile != null
                      ? Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: AppSpacing.blockSpacing),
                              Text(
                                'Carregando email...',
                                style: AppTypography.body,
                              ),
                            ],
                          ),
                        )
                      : AppInput(
                          label: 'E-mail',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email),
                          hint: 'usuario@exemplo.com',
                          enabled: widget.profile == null,
                          errorText: _emailError,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              setState(() {
                                _emailError = 'Digite o e-mail';
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
                    label: widget.profile == null
                        ? 'Senha'
                        : 'Nova Senha (opcional)',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock),
                    hint: 'Mínimo 6 caracteres',
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
                      if (widget.profile == null) {
                        if (value == null || value.isEmpty) {
                          setState(() {
                            _passwordError = 'Digite a senha';
                          });
                          return '';
                        }
                        if (value.length < 6) {
                          setState(() {
                            _passwordError = 'A senha deve ter no mínimo 6 caracteres';
                          });
                          return '';
                        }
                      } else {
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          setState(() {
                            _passwordError = 'A senha deve ter no mínimo 6 caracteres';
                          });
                          return '';
                        }
                      }
                      setState(() {
                        _passwordError = null;
                      });
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.blockSpacing),
                  AppInput(
                    label: widget.profile == null
                        ? 'Confirmar Senha'
                        : 'Confirmar Nova Senha',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    hint: widget.profile == null
                        ? 'Confirme a senha'
                        : 'Deixe em branco se não for alterar',
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
                      if (widget.profile == null) {
                        if (value == null || value.isEmpty) {
                          setState(() {
                            _confirmPasswordError = 'Confirme a senha';
                          });
                          return '';
                        }
                        if (value != _passwordController.text) {
                          setState(() {
                            _confirmPasswordError = 'As senhas não coincidem';
                          });
                          return '';
                        }
                      } else {
                        if (_passwordController.text.isNotEmpty) {
                          if (value == null || value.isEmpty) {
                            setState(() {
                              _confirmPasswordError = 'Confirme a nova senha';
                            });
                            return '';
                          }
                          if (value != _passwordController.text) {
                            setState(() {
                              _confirmPasswordError = 'As senhas não coincidem';
                            });
                            return '';
                          }
                        }
                      }
                      setState(() {
                        _confirmPasswordError = null;
                      });
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.blockSpacing),
                  if (_isLoadingCompanies)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    _companies.isEmpty
                        ? Text(
                            'Nenhuma empresa disponível',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Empresa',
                                style: AppTypography.label,
                              ),
                              const SizedBox(height: AppSpacing.labelInputSpacing),
                              DropdownButtonFormField<String>(
                                value: _selectedCompanyId,
                                decoration: InputDecoration(
                                  errorText: _companyError,
                                ),
                                items: _companies.map((company) {
                                  return DropdownMenuItem<String>(
                                    value: company['id'],
                                    child: Text(company['name'] ?? 'Sem nome'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCompanyId = value;
                                    _companyError = null;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    setState(() {
                                      _companyError = 'Selecione uma empresa';
                                    });
                                    return '';
                                  }
                                  return null;
                                },
                              ),
                              if (_companyError != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _companyError!,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  const SizedBox(height: AppSpacing.blockSpacing),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Função',
                        style: AppTypography.label,
                      ),
                      const SizedBox(height: AppSpacing.labelInputSpacing),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('Usuário')),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Administrador'),
                          ),
                          DropdownMenuItem(
                            value: 'owner',
                            child: Text('Proprietário'),
                          ),
                          DropdownMenuItem(
                            value: 'super_admin',
                            child: Text('Super Administrador'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRole = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    text: widget.profile == null
                        ? 'Criar Usuário'
                        : 'Salvar Alterações',
                    onPressed: _isLoading ? null : _handleSave,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppSpacing.blockSpacing),
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
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

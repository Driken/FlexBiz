import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_list_item.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/config/supabase_config.dart';
import '../../../data/repositories/company_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/company_model.dart';
import 'company_form_screen.dart';
import 'user_form_screen.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Painel de Administração'),
        bottom: isMobile
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.business), text: 'Empresas'),
                  Tab(icon: Icon(Icons.people), text: 'Usuários'),
                  Tab(icon: Icon(Icons.settings), text: 'Configurações'),
                ],
              )
            : null,
      ),
      body: isMobile ? _buildMobileContent() : _buildDesktopContent(),
    );
  }

  Widget _buildMobileContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _CompaniesView(),
        _UsersView(),
        _SettingsView(),
      ],
    );
  }

  Widget _buildDesktopContent() {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (_tabController.index != index) {
              _tabController.animateTo(index);
            }
          },
          labelType: NavigationRailLabelType.all,
          backgroundColor: AppColors.cardBackground,
          selectedIconTheme: const IconThemeData(color: AppColors.primary),
          selectedLabelTextStyle: AppTypography.body.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelTextStyle: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.business),
              selectedIcon: Icon(Icons.business),
              label: Text('Empresas'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.people),
              selectedIcon: Icon(Icons.people),
              label: Text('Usuários'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings),
              selectedIcon: Icon(Icons.settings),
              label: Text('Configurações'),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _CompaniesView();
      case 1:
        return _UsersView();
      case 2:
        return _SettingsView();
      default:
        return Center(
          child: Text(
            'Selecione uma opção',
            style: AppTypography.body,
          ),
        );
    }
  }
}

class _CompaniesView extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CompaniesView> createState() => _CompaniesViewState();
}

class _CompaniesViewState extends ConsumerState<_CompaniesView> {
  final _supabase = SupabaseConfig.client;
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _companies = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            boxShadow: [AppShadows.cardShadow],
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Empresas (${_companies.length})',
                      style: AppTypography.subtitle,
                    ),
                    const SizedBox(height: AppSpacing.blockSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Cadastrar',
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CompanyFormScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadCompanies();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadCompanies,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Empresas (${_companies.length})',
                      style: AppTypography.subtitle,
                    ),
                    Row(
                      children: [
                        AppButton(
                          text: 'Cadastrar',
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CompanyFormScreen(),
                              ),
                            );
                            if (result == true) {
                              _loadCompanies();
                            }
                          },
                          isFullWidth: false,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadCompanies,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _companies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 64,
                            color: AppColors.textDisabled,
                          ),
                          const SizedBox(height: AppSpacing.blockSpacing),
                          Text(
                            'Nenhuma empresa encontrada',
                            style: AppTypography.subtitle,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCompanies,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        itemCount: _companies.length,
                        itemBuilder: (context, index) {
                          final company = _companies[index];
                          String subtitle = '';
                          if (company['document'] != null) {
                            subtitle += 'CNPJ: ${company['document']}';
                          }
                          if (subtitle.isNotEmpty) subtitle += '\n';
                          subtitle += 'ID: ${company['id']}';
                          subtitle +=
                              '\nCriado em: ${_formatDate(company['created_at'])}';

                          return AppListItem(
                            title: company['name'] ?? 'Sem nome',
                            subtitle: subtitle,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primarySoft,
                              child: const Icon(
                                Icons.business,
                                color: AppColors.primary,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final companyModel =
                                      CompanyModel.fromJson(company);
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CompanyFormScreen(
                                        company: companyModel,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadCompanies();
                                  }
                                } else if (value == 'delete') {
                                  _showDeleteCompanyDialog(company);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: AppSpacing.sm),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          size: 20, color: AppColors.error),
                                      SizedBox(width: AppSpacing.sm),
                                      Text('Excluir',
                                          style: TextStyle(
                                              color: AppColors.error)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              final companyModel =
                                  CompanyModel.fromJson(company);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CompanyFormScreen(
                                    company: companyModel,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _loadCompanies();
                              }
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return date.toString();
    }
  }

  Future<void> _showDeleteCompanyDialog(Map<String, dynamic> company) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'Confirmar Exclusão',
          style: AppTypography.subtitle,
        ),
        content: Text(
          'Tem certeza que deseja excluir a empresa "${company['name']}"?\n\n'
          'Esta ação não pode ser desfeita.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: AppTypography.body.copyWith(color: AppColors.primary),
            ),
          ),
          AppButton(
            text: 'Excluir',
            variant: AppButtonVariant.danger,
            onPressed: () => Navigator.pop(context, true),
            isFullWidth: false,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = CompanyRepository();
        await repo.deleteCompany(company['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Empresa excluída com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadCompanies();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir empresa: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _UsersView extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends ConsumerState<_UsersView> {
  final _supabase = SupabaseConfig.client;
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('profiles')
          .select('*, companies(name)')
          .order('created_at', ascending: false);

      final profilesWithEmails = <Map<String, dynamic>>[];
      final authRepo = AuthRepository();

      for (var profile in response) {
        final profileMap = Map<String, dynamic>.from(profile);
        try {
          final email = await authRepo.getUserEmail(profile['id']);
          if (email != null) {
            profileMap['email'] = email;
          }
        } catch (e) {
          print('Erro ao buscar email para ${profile['id']}: $e');
        }
        profilesWithEmails.add(profileMap);
      }

      setState(() {
        _profiles = profilesWithEmails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar usuários: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            boxShadow: [AppShadows.cardShadow],
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Usuários (${_profiles.length})',
                      style: AppTypography.subtitle,
                    ),
                    const SizedBox(height: AppSpacing.blockSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Cadastrar',
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UserFormScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadProfiles();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadProfiles,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Usuários (${_profiles.length})',
                      style: AppTypography.subtitle,
                    ),
                    Row(
                      children: [
                        AppButton(
                          text: 'Cadastrar',
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UserFormScreen(),
                              ),
                            );
                            if (result == true) {
                              _loadProfiles();
                            }
                          },
                          isFullWidth: false,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadProfiles,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _profiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.textDisabled,
                          ),
                          const SizedBox(height: AppSpacing.blockSpacing),
                          Text(
                            'Nenhum usuário encontrado',
                            style: AppTypography.subtitle,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProfiles,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        itemCount: _profiles.length,
                        itemBuilder: (context, index) {
                          final profile = _profiles[index];
                          final company = profile['companies'];
                          final role = profile['role'] ?? 'user';
                          Color roleColor = AppColors.textSecondary;
                          String roleLabel = 'Usuário';
                          if (role == 'super_admin') {
                            roleColor = Colors.purple;
                            roleLabel = 'Super Admin';
                          } else if (role == 'owner') {
                            roleColor = AppColors.info;
                            roleLabel = 'Proprietário';
                          } else if (role == 'admin') {
                            roleColor = AppColors.success;
                            roleLabel = 'Administrador';
                          }

                          String subtitle = roleLabel;
                          if (company != null) {
                            subtitle += '\nEmpresa: ${company['name']}';
                          }
                          subtitle += '\nID: ${profile['id']}';

                          return AppListItem(
                            title: profile['name'] ?? 'Sem nome',
                            subtitle: subtitle,
                            leading: CircleAvatar(
                              backgroundColor: roleColor.withOpacity(0.1),
                              child: Text(
                                (profile['name'] ?? 'U')[0].toUpperCase(),
                                style: AppTypography.body.copyWith(
                                  color: roleColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserFormScreen(
                                        profile: profile,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadProfiles();
                                  }
                                } else if (value == 'delete') {
                                  _showDeleteUserDialog(profile);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: AppSpacing.sm),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          size: 20, color: AppColors.error),
                                      SizedBox(width: AppSpacing.sm),
                                      Text('Excluir',
                                          style: TextStyle(
                                              color: AppColors.error)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserFormScreen(
                                    profile: profile,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _loadProfiles();
                              }
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Future<void> _showDeleteUserDialog(Map<String, dynamic> profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'Confirmar Exclusão',
          style: AppTypography.subtitle,
        ),
        content: Text(
          'Tem certeza que deseja excluir o usuário "${profile['name']}"?\n\n'
          'Esta ação não pode ser desfeita.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: AppTypography.body.copyWith(color: AppColors.primary),
            ),
          ),
          AppButton(
            text: 'Excluir',
            variant: AppButtonVariant.danger,
            onPressed: () => Navigator.pop(context, true),
            isFullWidth: false,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authRepo = AuthRepository();
        await authRepo.deleteUser(profile['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário excluído com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadProfiles();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir usuário: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.blockSpacing),
            Text(
              'Configurações do Sistema',
              style: AppTypography.subtitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Esta seção está em desenvolvimento.\n'
              'Aqui você poderá configurar parâmetros globais do sistema.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

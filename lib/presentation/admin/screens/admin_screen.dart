import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import 'user_form_dialog.dart';
import 'user_edit_dialog.dart';
import 'company_form_dialog.dart';
import 'settings_view.dart';
import '../../../data/repositories/company_repository.dart';
import '../../../data/repositories/auth_repository.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _selectedIndex = 0;
  final _companiesViewKey = GlobalKey<_CompaniesViewState>();
  final _usersViewKey = GlobalKey<_UsersViewState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Se houver uma rota anterior na pilha, volta para ela
            // Caso contrário, vai para o Dashboard
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            }
          },
          tooltip: 'Voltar',
        ),
        title: const Text('Painel de Administração'),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
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
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _CompaniesView(key: _companiesViewKey);
      case 1:
        return _UsersView(key: _usersViewKey);
      case 2:
        return _SettingsView();
      default:
        return const Center(child: Text('Selecione uma opção'));
    }
  }

  Widget? _buildFloatingActionButton() {
    if (_selectedIndex == 2) return null; // Sem FAB na aba de configurações

    return FloatingActionButton(
      onPressed: () async {
        final result = _selectedIndex == 0
            ? await CompanyFormDialog.show(context)
            : await UserFormDialog.show(context);
        if (result == true) {
          // Recarregar dados após criar
          if (_selectedIndex == 0) {
            _companiesViewKey.currentState?.loadCompanies();
          } else {
            _usersViewKey.currentState?.loadProfiles();
          }
        }
      },
      child: const Icon(Icons.add),
    );
  }
}

class _CompaniesView extends ConsumerStatefulWidget {
  const _CompaniesView({super.key});

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

  void loadCompanies() {
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
          SnackBar(content: Text('Erro ao carregar empresas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Empresas (${_companies.length})',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadCompanies,
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma empresa encontrada',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toque no + para adicionar',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCompanies,
                      child: ListView.builder(
                        itemCount: _companies.length,
                        itemBuilder: (context, index) {
                          final company = _companies[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.business),
                              title: Text(company['name'] ?? 'Sem nome'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (company['document'] != null)
                                    Text('CNPJ: ${company['document']}'),
                                  Text(
                                    'ID: ${company['id']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Criado em: ${_formatDate(company['created_at'])}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    await _confirmDeleteCompany(
                                      context,
                                      company['id'] as String,
                                      company['name'] as String? ?? 'Sem nome',
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Excluir', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Future<void> _confirmDeleteCompany(
    BuildContext context,
    String companyId,
    String companyName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tem certeza que deseja excluir esta empresa?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      companyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ATENÇÃO: Todos os dados associados a esta empresa serão perdidos.\nEsta ação não pode ser desfeita.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = CompanyRepository();
        await repo.deleteCompany(companyId);
        
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
  const _UsersView({super.key});

  @override
  ConsumerState<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends ConsumerState<_UsersView> {
  final _supabase = SupabaseConfig.client;
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _allProfiles = [];
  List<Map<String, dynamic>> _companies = [];
  String? _selectedCompanyId; // null = todas as empresas
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _loadProfiles();
  }

  void loadProfiles() {
    _loadProfiles();
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

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      // Buscar todos os perfis com informações da empresa
      final response = await _supabase
          .from('profiles')
          .select('*, companies(name)')
          .order('created_at', ascending: false);
      
      if (mounted) {
        final profilesList = List<Map<String, dynamic>>.from(response);
        setState(() {
          _allProfiles = profilesList;
          _applyFilter();
          _isLoading = false;
        });
        
        // Debug: mostrar quantos perfis foram carregados
        print('Perfis carregados: ${profilesList.length}');
        if (profilesList.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhum usuário encontrado. Verifique as permissões RLS.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar usuários: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        print('Erro ao carregar perfis: $e');
      }
    }
  }

  void _applyFilter() {
    if (_selectedCompanyId == null) {
      // Mostrar todos os usuários
      setState(() {
        _profiles = List.from(_allProfiles);
      });
    } else {
      // Filtrar por empresa selecionada
      setState(() {
        _profiles = _allProfiles
            .where((profile) => profile['company_id'] == _selectedCompanyId)
            .toList();
      });
    }
  }

  void _onCompanyFilterChanged(String? companyId) {
    setState(() {
      _selectedCompanyId = companyId;
    });
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Usuários (${_profiles.length})',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadProfiles,
                    tooltip: 'Atualizar lista',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Filtro por empresa
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedCompanyId,
                    isExpanded: true,
                    hint: const Row(
                      children: [
                        Icon(Icons.filter_list, size: 20),
                        SizedBox(width: 8),
                        Text('Filtrar por empresa'),
                      ],
                    ),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(Icons.business_center, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Todas as empresas'),
                          ],
                        ),
                      ),
                      ..._companies.map((company) {
                        return DropdownMenuItem<String?>(
                          value: company['id'] as String,
                          child: Row(
                            children: [
                              const Icon(Icons.business, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(company['name'] as String),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: _onCompanyFilterChanged,
                  ),
                ),
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum usuário encontrado',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toque no + para adicionar',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProfiles,
                      child: ListView.builder(
                        itemCount: _profiles.length,
                        itemBuilder: (context, index) {
                          final profile = _profiles[index];
                          final company = profile['companies'];
                          final role = profile['role'] ?? 'user';
                          Color roleColor = Colors.grey;
                          if (role == 'super_admin') {
                            roleColor = Colors.purple;
                          } else if (role == 'owner') {
                            roleColor = Colors.blue;
                          } else if (role == 'admin') {
                            roleColor = Colors.green;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: roleColor,
                                child: Text(
                                  (profile['name'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(profile['name'] ?? 'Sem nome'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: roleColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          role.toUpperCase(),
                                          style: TextStyle(
                                            color: roleColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (company != null)
                                    Text('Empresa: ${company['name']}'),
                                  Text(
                                    'ID: ${profile['id']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    // Buscar email do usuário usando função stored procedure
                                    String? userEmail;
                                    try {
                                      final emailResponse = await _supabase.rpc(
                                        'get_user_email',
                                        params: {'p_user_id': profile['id']},
                                      );
                                      userEmail = emailResponse as String?;
                                    } catch (e) {
                                      // Se não conseguir buscar, continua sem email
                                      print('Não foi possível buscar email: $e');
                                    }
                                    
                                    final result = await UserEditDialog.show(
                                      context,
                                      userId: profile['id'],
                                      currentName: profile['name'] ?? '',
                                      currentEmail: userEmail,
                                      currentCompanyId: profile['company_id'],
                                      currentRole: role,
                                    );
                                    
                                    if (result == true) {
                                      _loadProfiles();
                                    }
                                  } else if (value == 'delete') {
                                    await _confirmDeleteUser(
                                      context,
                                      profile['id'] as String,
                                      profile['name'] as String? ?? 'Sem nome',
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Excluir', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    String userId,
    String userName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tem certeza que deseja excluir este usuário?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ATENÇÃO: O usuário perderá acesso ao sistema.\nEsta ação não pode ser desfeita.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = AuthRepository();
        await repo.deleteUser(userId);
        
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
    return const SettingsView();
  }
}


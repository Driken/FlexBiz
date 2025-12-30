import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../data/models/settings_model.dart';
import '../../../data/repositories/settings_repository.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _settingsRepository = SettingsRepository();
  final _supabase = SupabaseConfig.client;
  
  SystemSettings? _settings;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _currentCompanyId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      // Para admin, buscar a primeira empresa ou permitir seleção
      final companiesResponse = await _supabase
          .from('companies')
          .select('id, name')
          .limit(1)
          .single();
      
      _currentCompanyId = companiesResponse['id'] as String;
      
      final settings = await _settingsRepository.getSettings(_currentCompanyId!);
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar configurações: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null || _currentCompanyId == null) return;
    
    setState(() => _isSaving = true);
    try {
      await _settingsRepository.saveSettings(_currentCompanyId!, _settings!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_settings == null) {
      return const Center(child: Text('Erro ao carregar configurações'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildGeneralSettings(),
          const SizedBox(height: 24),
          _buildFinancialSettings(),
          const SizedBox(height: 24),
          _buildNotificationsSettings(),
          const SizedBox(height: 24),
          _buildSecuritySettings(),
          const SizedBox(height: 24),
          _buildBackupSettings(),
          const SizedBox(height: 24),
          _buildReportsSettings(),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 32, color: Colors.purple),
                const SizedBox(width: 12),
                Text(
                  'Configurações do Sistema',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure os parâmetros globais do sistema',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSettingsSection(
      title: 'Configurações Gerais',
      icon: Icons.tune,
      children: [
        DropdownButtonFormField<String>(
          value: _settings!.currency,
          decoration: const InputDecoration(
            labelText: 'Moeda',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: 'BRL', child: Text('Real (BRL)')),
            DropdownMenuItem(value: 'USD', child: Text('Dólar (USD)')),
            DropdownMenuItem(value: 'EUR', child: Text('Euro (EUR)')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _settings = _settings!.copyWith(currency: value);
              });
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _settings!.currencySymbol,
          decoration: const InputDecoration(
            labelText: 'Símbolo da Moeda',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(currencySymbol: value);
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _settings!.dateFormat,
          decoration: const InputDecoration(
            labelText: 'Formato de Data',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('DD/MM/AAAA')),
            DropdownMenuItem(value: 'MM/dd/yyyy', child: Text('MM/DD/AAAA')),
            DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('AAAA-MM-DD')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _settings = _settings!.copyWith(dateFormat: value);
              });
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _settings!.timeZone,
          decoration: const InputDecoration(
            labelText: 'Fuso Horário',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: 'America/Sao_Paulo', child: Text('Brasil (GMT-3)')),
            DropdownMenuItem(value: 'America/New_York', child: Text('EUA Leste (GMT-5)')),
            DropdownMenuItem(value: 'Europe/London', child: Text('Londres (GMT+0)')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _settings = _settings!.copyWith(timeZone: value);
              });
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _settings!.language,
          decoration: const InputDecoration(
            labelText: 'Idioma',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: 'pt_BR', child: Text('Português (Brasil)')),
            DropdownMenuItem(value: 'en_US', child: Text('English (US)')),
            DropdownMenuItem(value: 'es_ES', child: Text('Español')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _settings = _settings!.copyWith(language: value);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildFinancialSettings() {
    return _buildSettingsSection(
      title: 'Configurações Financeiras',
      icon: Icons.attach_money,
      children: [
        TextFormField(
          initialValue: _settings!.defaultTaxRate?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'Taxa de Imposto Padrão (%)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
            helperText: 'Ex: 18 para 18%',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final tax = double.tryParse(value);
            setState(() {
              _settings = _settings!.copyWith(defaultTaxRate: tax);
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _settings!.defaultInterestRate?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'Taxa de Juros Padrão (%)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final interest = double.tryParse(value);
            setState(() {
              _settings = _settings!.copyWith(defaultInterestRate: interest);
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _settings!.defaultPaymentDays.toString(),
          decoration: const InputDecoration(
            labelText: 'Prazo de Pagamento Padrão (dias)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final days = int.tryParse(value);
            if (days != null) {
              setState(() {
                _settings = _settings!.copyWith(defaultPaymentDays: days);
              });
            }
          },
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Gerar Contas a Receber Automaticamente'),
          subtitle: const Text('Ao criar pedidos, gerar contas automaticamente'),
          value: _settings!.autoGenerateReceivables,
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(autoGenerateReceivables: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildNotificationsSettings() {
    return _buildSettingsSection(
      title: 'Configurações de Notificações',
      icon: Icons.notifications,
      children: [
        SwitchListTile(
          title: const Text('Habilitar Notificações por Email'),
          value: _settings!.enableEmailNotifications,
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(enableEmailNotifications: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Habilitar Notificações por SMS'),
          value: _settings!.enableSmsNotifications,
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(enableSmsNotifications: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _settings!.daysBeforeDueDateAlert.toString(),
          decoration: const InputDecoration(
            labelText: 'Dias Antes do Vencimento para Alerta',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final days = int.tryParse(value);
            if (days != null) {
              setState(() {
                _settings = _settings!.copyWith(daysBeforeDueDateAlert: days);
              });
            }
          },
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Notificar ao Criar Novo Pedido'),
          value: _settings!.notifyOnNewOrder,
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(notifyOnNewOrder: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Notificar ao Receber Pagamento'),
          value: _settings!.notifyOnPayment,
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(notifyOnPayment: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return _buildSettingsSection(
      title: 'Configurações de Segurança',
      icon: Icons.security,
      children: [
        TextFormField(
          initialValue: _settings!.sessionTimeoutMinutes.toString(),
          decoration: const InputDecoration(
            labelText: 'Timeout de Sessão (minutos)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final minutes = int.tryParse(value);
            if (minutes != null) {
              setState(() {
                _settings = _settings!.copyWith(sessionTimeoutMinutes: minutes);
              });
            }
          },
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Exigir Senha Forte'),
          subtitle: const Text('Mínimo de 8 caracteres, números e símbolos'),
          value: _settings!.requireStrongPassword,
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(requireStrongPassword: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Habilitar Autenticação de Dois Fatores'),
          value: _settings!.enableTwoFactorAuth,
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(enableTwoFactorAuth: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _settings!.maxLoginAttempts.toString(),
          decoration: const InputDecoration(
            labelText: 'Máximo de Tentativas de Login',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final attempts = int.tryParse(value);
            if (attempts != null) {
              setState(() {
                _settings = _settings!.copyWith(maxLoginAttempts: attempts);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildBackupSettings() {
    return _buildSettingsSection(
      title: 'Configurações de Backup',
      icon: Icons.backup,
      children: [
        SwitchListTile(
          title: const Text('Habilitar Backup Automático'),
          value: _settings!.enableAutoBackup,
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(enableAutoBackup: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (_settings!.enableAutoBackup) ...[
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _settings!.backupFrequencyDays.toString(),
            decoration: const InputDecoration(
              labelText: 'Frequência de Backup (dias)',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final days = int.tryParse(value);
              if (days != null) {
                setState(() {
                  _settings = _settings!.copyWith(backupFrequencyDays: days);
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _settings!.backupEmail ?? '',
            decoration: const InputDecoration(
              labelText: 'Email para Receber Backups',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              setState(() {
                _settings = _settings!.copyWith(backupEmail: value.isEmpty ? null : value);
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildReportsSettings() {
    return _buildSettingsSection(
      title: 'Configurações de Relatórios',
      icon: Icons.assessment,
      children: [
        SwitchListTile(
          title: const Text('Habilitar Relatórios'),
          value: _settings!.enableReports,
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(enableReports: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _settings!.reportDateFormat,
          decoration: const InputDecoration(
            labelText: 'Formato de Data nos Relatórios',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('DD/MM/AAAA')),
            DropdownMenuItem(value: 'MM/dd/yyyy', child: Text('MM/DD/AAAA')),
            DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('AAAA-MM-DD')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _settings = _settings!.copyWith(reportDateFormat: value);
              });
            }
          },
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Incluir Itens Inativos nos Relatórios'),
          value: _settings!.includeInactiveItems,
          onChanged: (value) {
            setState(() {
              _settings = _settings!.copyWith(includeInactiveItems: value);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : () async {
              await _settingsRepository.resetToDefaults(_currentCompanyId!);
              await _loadSettings();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configurações resetadas para padrão'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            icon: const Icon(Icons.restore),
            label: const Text('Restaurar Padrões'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Salvando...' : 'Salvar Configurações'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}


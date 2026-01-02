import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_list_item.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../data/models/account_payable_model.dart';
import '../../../../data/repositories/account_payable_repository.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/providers/session_provider.dart';
import '../providers/accounts_payable_provider.dart';
import 'account_payable_form_screen.dart';

class AccountsPayableScreen extends ConsumerStatefulWidget {
  const AccountsPayableScreen({super.key});

  @override
  ConsumerState<AccountsPayableScreen> createState() =>
      _AccountsPayableScreenState();
}

class _AccountsPayableScreenState extends ConsumerState<AccountsPayableScreen> {
  String? _selectedFilter;

  FinancialStatus _getStatus(String? status) {
    if (status == 'paid') return FinancialStatus.paid;
    if (status == 'late') return FinancialStatus.late;
    return FinancialStatus.open;
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Contas a Pagar'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value == 'all' ? null : value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todas')),
              const PopupMenuItem(value: 'open', child: Text('Abertas')),
              const PopupMenuItem(value: 'paid', child: Text('Pagas')),
              const PopupMenuItem(value: 'late', child: Text('Atrasadas')),
            ],
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return Center(
              child: Text(
                'Sessão não encontrada',
                style: AppTypography.body,
              ),
            );
          }

          final accountsAsync =
              ref.watch(accountsPayableProvider(session.companyId));

          return accountsAsync.when(
            data: (accounts) {
              final filteredAccounts = _selectedFilter == null
                  ? accounts
                  : accounts
                      .where((a) => a.status == _selectedFilter!)
                      .toList();

              if (filteredAccounts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_upward_outlined,
                        size: 64,
                        color: AppColors.textDisabled,
                      ),
                      const SizedBox(height: AppSpacing.blockSpacing),
                      Text(
                        'Nenhuma conta encontrada',
                        style: AppTypography.subtitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Toque no + para adicionar',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(accountsPayableProvider(session.companyId));
                },
                child: ListView.builder(
                  itemCount: filteredAccounts.length,
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  itemBuilder: (context, index) {
                    final account = filteredAccounts[index];
                    final status = _getStatus(account.status);

                    String subtitle = '';
                    if (account.supplierName != null) {
                      subtitle += 'Fornecedor: ${account.supplierName}';
                    }
                    if (account.dueDate != null) {
                      if (subtitle.isNotEmpty) subtitle += '\n';
                      subtitle +=
                          'Vencimento: ${app_date_utils.DateUtils.formatDate(account.dueDate)}';
                    }
                    if (account.paymentDate != null) {
                      if (subtitle.isNotEmpty) subtitle += '\n';
                      subtitle +=
                          'Pagamento: ${app_date_utils.DateUtils.formatDate(account.paymentDate)}';
                    }

                    Color iconColor;
                    IconData iconData;
                    if (account.isPaid) {
                      iconColor = AppColors.statusPaid;
                      iconData = Icons.check;
                    } else if (account.isLate) {
                      iconColor = AppColors.statusLate;
                      iconData = Icons.warning;
                    } else {
                      iconColor = AppColors.statusOpen;
                      iconData = Icons.schedule;
                    }

                    return AppListItem(
                      title: account.description ?? 'Sem descrição',
                      subtitle: subtitle.isNotEmpty ? subtitle : null,
                      leading: CircleAvatar(
                        backgroundColor: iconColor.withOpacity(0.1),
                        child: Icon(iconData, color: iconColor),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyUtils.format(account.amount),
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          StatusBadge(status: status),
                        ],
                      ),
                      onTap: account.isPaid
                          ? null
                          : () {
                              _showMarkAsPaidDialog(account, session.companyId);
                            },
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Erro: $error',
                style: AppTypography.body.copyWith(color: AppColors.error),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Erro: $error',
            style: AppTypography.body.copyWith(color: AppColors.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountPayableFormScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textInverse),
      ),
    );
  }

  void _showMarkAsPaidDialog(AccountPayableModel account, String companyId) {
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(
            'Marcar como Pago',
            style: AppTypography.subtitle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Valor: ${CurrencyUtils.format(account.amount)}',
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.blockSpacing),
              OutlinedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() {
                      selectedDate = date;
                    });
                  }
                },
                child: Text(
                  'Data de Pagamento: ${app_date_utils.DateUtils.formatDate(selectedDate)}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: AppTypography.body.copyWith(color: AppColors.primary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await AccountPayableRepository()
                      .markAsPaid(account.id, selectedDate);
                  ref.invalidate(accountsPayableProvider(companyId));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Conta marcada como paga!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro: ${e.toString()}'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}

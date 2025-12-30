import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/account_payable_model.dart';
import '../../../data/repositories/account_payable_repository.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/providers/session_provider.dart';
import '../providers/accounts_payable_provider.dart';
import '../screens/account_payable_form_screen.dart';

class AccountsPayableScreen extends ConsumerStatefulWidget {
  const AccountsPayableScreen({super.key});

  @override
  ConsumerState<AccountsPayableScreen> createState() =>
      _AccountsPayableScreenState();
}

class _AccountsPayableScreenState extends ConsumerState<AccountsPayableScreen> {
  String? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider);

    return Scaffold(
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
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Sessão não encontrada'));
          }

          final accountsAsync =
              ref.watch(accountsPayableProvider(session.companyId));

          return accountsAsync.when(
            data: (accounts) {
              final filteredAccounts = _selectedFilter == null
                  ? accounts
                  : accounts
                      .where((a) => a.status == _selectedFilter)
                      .toList();

              if (filteredAccounts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_upward_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma conta encontrada',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no + para adicionar',
                        style: Theme.of(context).textTheme.bodyMedium,
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
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final account = filteredAccounts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: account.isLate
                          ? Colors.red[50]
                          : account.isPaid
                              ? Colors.green[50]
                              : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: account.isLate
                              ? Colors.red
                              : account.isPaid
                                  ? Colors.green
                                  : Colors.orange,
                          child: Icon(
                            account.isPaid
                                ? Icons.check
                                : account.isLate
                                    ? Icons.warning
                                    : Icons.schedule,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(account.description ?? 'Sem descrição'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (account.supplierName != null)
                              Text('Fornecedor: ${account.supplierName}'),
                            if (account.dueDate != null)
                              Text(
                                'Vencimento: ${DateUtils.formatDate(account.dueDate)}',
                              ),
                            if (account.paymentDate != null)
                              Text(
                                'Pagamento: ${DateUtils.formatDate(account.paymentDate)}',
                                style: const TextStyle(color: Colors.green),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyUtils.format(account.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Chip(
                              label: Text(
                                account.status == 'open'
                                    ? 'Aberto'
                                    : account.status == 'paid'
                                        ? 'Pago'
                                        : 'Atrasado',
                              ),
                              backgroundColor: account.status == 'open'
                                  ? Colors.orange[100]
                                  : account.status == 'paid'
                                      ? Colors.green[100]
                                      : Colors.red[100],
                            ),
                          ],
                        ),
                        onTap: account.isPaid
                            ? null
                            : () {
                                _showMarkAsPaidDialog(account, session.companyId);
                              },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Erro: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erro: $error')),
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
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showMarkAsPaidDialog(
      AccountPayableModel account, String companyId) {
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Marcar como Pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Valor: ${CurrencyUtils.format(account.amount)}'),
              const SizedBox(height: 16),
              TextButton(
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
                  'Data de Pagamento: ${DateUtils.formatDate(selectedDate)}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
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
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro: ${e.toString()}'),
                        backgroundColor: Colors.red,
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


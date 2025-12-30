import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/kpi_card.dart';
import '../../shared/providers/session_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/account_receivable_model.dart';
import '../../accounts/receivable/screens/accounts_receivable_screen.dart';
import '../../accounts/payable/screens/accounts_payable_screen.dart';
import '../../items/screens/items_list_screen.dart';
import '../../customers/screens/customers_list_screen.dart';
import '../../orders/screens/orders_list_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: const AppDrawer(),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Sessão não encontrada'));
          }

          final dashboardAsync =
              ref.watch(dashboardProvider(session.companyId));
          final upcomingAsync =
              ref.watch(upcomingAccountsProvider(session.companyId));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardProvider(session.companyId));
              ref.invalidate(upcomingAccountsProvider(session.companyId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dashboardAsync.when(
                    data: (data) => Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: KPICard(
                                title: 'A Receber Hoje',
                                value: data.totalReceivableToday,
                                icon: Icons.arrow_downward,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: KPICard(
                                title: 'A Pagar Hoje',
                                value: data.totalPayableToday,
                                icon: Icons.arrow_upward,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: KPICard(
                                title: 'A Receber no Mês',
                                value: data.totalReceivableMonth,
                                icon: Icons.trending_up,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: KPICard(
                                title: 'A Pagar no Mês',
                                value: data.totalPayableMonth,
                                icon: Icons.trending_down,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        KPICard(
                          title: 'Saldo Previsto do Mês',
                          value: data.projectedBalance,
                          icon: data.projectedBalance >= 0
                              ? Icons.account_balance
                              : Icons.warning,
                          color: data.projectedBalance >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Text('Erro: $error'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Próximos Vencimentos (7 dias)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  upcomingAsync.when(
                    data: (accounts) {
                      if (accounts.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Nenhum vencimento próximo'),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: Text(account.description ?? 'Sem descrição'),
                              subtitle: Text(
                                'Vence em: ${DateUtils.formatDate(account.dueDate)}',
                              ),
                              trailing: Text(
                                CurrencyUtils.format(account.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Text('Erro: $error'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Ações Rápidas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: [
                      _QuickActionCard(
                        title: 'Itens',
                        icon: Icons.inventory_2,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ItemsListScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickActionCard(
                        title: 'Clientes',
                        icon: Icons.people,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomersListScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickActionCard(
                        title: 'Pedidos',
                        icon: Icons.shopping_cart,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OrdersListScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickActionCard(
                        title: 'Contas a Receber',
                        icon: Icons.arrow_downward,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AccountsReceivableScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickActionCard(
                        title: 'Contas a Pagar',
                        icon: Icons.arrow_upward,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AccountsPayableScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erro: $error')),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


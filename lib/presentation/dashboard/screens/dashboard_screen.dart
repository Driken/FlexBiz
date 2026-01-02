import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_list_item.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/kpi_card.dart';
import '../../shared/providers/session_provider.dart';
import '../providers/dashboard_provider.dart';
import 'package:flexbiz/core/utils/currency_utils.dart';
import 'package:flexbiz/core/utils/date_utils.dart' as app_date_utils;
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
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
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width < 600 ? 420 : 1200,
                  ),
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
                                    color: AppColors.statusPaid,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.blockSpacing),
                                Expanded(
                                  child: KPICard(
                                    title: 'A Pagar Hoje',
                                    value: data.totalPayableToday,
                                    icon: Icons.arrow_upward,
                                    color: AppColors.statusLate,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.blockSpacing),
                            Row(
                            children: [
                              Expanded(
                                child: KPICard(
                                  title: 'A Receber no Mês',
                                  value: data.totalReceivableMonth,
                                  icon: Icons.trending_up,
                                  color: AppColors.info,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.blockSpacing),
                              Expanded(
                                child: KPICard(
                                  title: 'A Pagar no Mês',
                                  value: data.totalPayableMonth,
                                  icon: Icons.trending_down,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                            const SizedBox(height: AppSpacing.blockSpacing),
                            KPICard(
                              title: 'Saldo Previsto do Mês',
                              value: data.projectedBalance,
                              icon: data.projectedBalance >= 0
                                  ? Icons.account_balance
                                  : Icons.warning,
                              color: data.projectedBalance >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                        ],
                      ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xxl),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, stack) => Center(
                          child: Text(
                            'Erro: $error',
                            style: AppTypography.body.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'Próximos Vencimentos (7 dias)',
                        style: AppTypography.subtitle,
                      ),
                      const SizedBox(height: AppSpacing.blockSpacing),
                      upcomingAsync.when(
                      data: (accounts) {
                        if (accounts.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              boxShadow: [AppShadows.cardShadow],
                            ),
                            child: Text(
                              'Nenhum vencimento próximo',
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            final account = accounts[index];
                            return AppListItem(
                              title: account.description ?? 'Sem descrição',
                              subtitle:
                                  'Vence em: ${app_date_utils.DateUtils.formatDate(account.dueDate)}',
                              leading: const Icon(
                                Icons.calendar_today,
                                color: AppColors.textSecondary,
                              ),
                              trailing: Text(
                                CurrencyUtils.format(account.amount),
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.blockSpacing),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Text(
                          'Erro: $error',
                          style: AppTypography.body.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'Ações Rápidas',
                        style: AppTypography.subtitle,
                      ),
                      const SizedBox(height: AppSpacing.blockSpacing),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.blockSpacing,
                        mainAxisSpacing: AppSpacing.blockSpacing,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


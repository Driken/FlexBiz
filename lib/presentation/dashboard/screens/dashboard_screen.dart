import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dashboardAsync.when(
                    data: (data) => Column(
                      children: [
                        // Primeira linha - Hoje
                        Row(
                          children: [
                            Expanded(
                              child: KPICard(
                                title: 'A Receber Hoje',
                                value: data.totalReceivableToday,
                                icon: Icons.arrow_downward,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: KPICard(
                                title: 'A Pagar Hoje',
                                value: data.totalPayableToday,
                                icon: Icons.arrow_upward,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Segunda linha - Mês
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
                            const SizedBox(width: 24),
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
                        const SizedBox(height: 24),
                        // Card destacado - Saldo Previsto
                        KPICard(
                          title: 'Saldo Previsto do Mês',
                          value: data.projectedBalance,
                          icon: data.projectedBalance >= 0
                              ? Icons.account_balance_wallet
                              : Icons.warning_rounded,
                          color: data.projectedBalance >= 0
                              ? AppColors.success
                              : AppColors.error,
                          isHighlighted: true,
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
                  const SizedBox(height: 40),
                  Text(
                    'Próximos Vencimentos (7 dias)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 20),
                  upcomingAsync.when(
                    data: (accounts) {
                      if (accounts.isEmpty) {
                        return _EmptyState(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'Tudo em dia por aqui! ✨',
                          subtitle:
                              'Você não tem contas vencendo nos próximos 7 dias.',
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  color: AppColors.warning,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                account.description ?? 'Sem descrição',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Vence em: ${app_date_utils.DateUtils.formatDate(account.dueDate)}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              trailing: Text(
                                CurrencyUtils.format(account.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
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
                  const SizedBox(height: 40),
                  Text(
                    'Ações Rápidas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
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

class _QuickActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -2.0 : 0.0),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovered ? 0.06 : 0.04),
                    blurRadius: _isHovered ? 12 : 8,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.info,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


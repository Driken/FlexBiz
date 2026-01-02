import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_list_item.dart';
import '../../../core/widgets/status_badge.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/providers/session_provider.dart';
import '../providers/orders_provider.dart';
import '../screens/order_form_screen.dart';
import '../screens/order_detail_screen.dart';
import 'package:flexbiz/core/utils/currency_utils.dart';
import 'package:flexbiz/core/utils/date_utils.dart' as app_date_utils;

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pedidos'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedStatus = value == 'all' ? null : value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todos')),
              const PopupMenuItem(value: 'open', child: Text('Abertos')),
              const PopupMenuItem(value: 'completed', child: Text('Concluídos')),
              const PopupMenuItem(value: 'canceled', child: Text('Cancelados')),
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

          final ordersAsync = ref.watch(ordersProvider(session.companyId));

          return ordersAsync.when(
            data: (orders) {
              final filteredOrders = _selectedStatus == null
                  ? orders
                  : orders.where((o) => o.status == _selectedStatus).toList();

              if (filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: AppColors.textDisabled,
                      ),
                      const SizedBox(height: AppSpacing.blockSpacing),
                      Text(
                        'Nenhum pedido encontrado',
                        style: AppTypography.subtitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Toque no + para criar um pedido',
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
                  ref.invalidate(ordersProvider(session.companyId));
                },
                child: ListView.builder(
                  itemCount: filteredOrders.length,
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    FinancialStatus status;
                    if (order.status == 'open') {
                      status = FinancialStatus.open;
                    } else if (order.status == 'completed') {
                      status = FinancialStatus.paid;
                    } else {
                      status = FinancialStatus.canceled;
                    }

                    String subtitle =
                        app_date_utils.DateUtils.formatDate(order.orderDate);
                    if (order.totalAmount != null) {
                      subtitle += '\n${CurrencyUtils.format(order.totalAmount!)}';
                    }

                    Color iconColor;
                    IconData iconData;
                    if (order.isOpen) {
                      iconColor = AppColors.statusOpen;
                      iconData = Icons.shopping_cart;
                    } else if (order.isCompleted) {
                      iconColor = AppColors.statusPaid;
                      iconData = Icons.check;
                    } else {
                      iconColor = AppColors.statusCanceled;
                      iconData = Icons.cancel;
                    }

                    return AppListItem(
                      title: 'Pedido #${order.id.substring(0, 8)}',
                      subtitle: subtitle,
                      leading: CircleAvatar(
                        backgroundColor: iconColor.withOpacity(0.1),
                        child: Icon(iconData, color: iconColor),
                      ),
                      trailing: StatusBadge(
                        status: status,
                        customLabel: order.status == 'open'
                            ? 'Aberto'
                            : order.status == 'completed'
                                ? 'Concluído'
                                : 'Cancelado',
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderDetailScreen(orderId: order.id),
                          ),
                        );
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
              builder: (context) => const OrderFormScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textInverse),
      ),
    );
  }
}


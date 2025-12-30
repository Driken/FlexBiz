import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/session_provider.dart';
import '../providers/orders_provider.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/account_receivable_repository.dart';
import 'package:flexbiz/core/utils/currency_utils.dart';
import 'package:flexbiz/core/utils/date_utils.dart' as app_date_utils;
import '../../../data/models/order_item_model.dart';
import '../../../data/models/account_receivable_model.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final sessionAsync = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Pedido'),
      ),
      body: orderAsync.when(
        data: (order) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido #${order.id.substring(0, 8)}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Data',
                          value: app_date_utils.DateUtils.formatDate(order.orderDate),
                        ),
                        _DetailRow(
                          label: 'Status',
                          value: order.status == 'open'
                              ? 'Aberto'
                              : order.status == 'completed'
                                  ? 'Concluído'
                                  : 'Cancelado',
                        ),
                        _DetailRow(
                          label: 'Forma de Pagamento',
                          value: order.paymentType == 'cash'
                              ? 'À Vista'
                              : 'Parcelado',
                        ),
                        if (order.totalAmount != null)
                          _DetailRow(
                            label: 'Valor Total',
                            value: CurrencyUtils.format(order.totalAmount!),
                            isBold: true,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<OrderItemModel>>(
                  future: OrderRepository().getOrderItems(orderId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Erro ao carregar itens'),
                        ),
                      );
                    }

                    final items = snapshot.data!;

                    return Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Itens do Pedido',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...items.map((item) {
                            return ListTile(
                              title: Text('Item ID: ${item.itemId.substring(0, 8)}'),
                              subtitle: Text(
                                '${item.quantity} x ${CurrencyUtils.format(item.unitPrice)}',
                              ),
                              trailing: Text(
                                CurrencyUtils.format(item.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<AccountReceivableModel>>(
                  future: AccountReceivableRepository()
                      .getAccounts(sessionAsync.value!.companyId, status: null)
                      .then((accounts) => accounts
                          .where((a) => a.orderId == orderId)
                          .toList()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final accounts = snapshot.data!;

                    if (accounts.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Contas a Receber Geradas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...accounts.map((account) {
                            return ListTile(
                              title: Text(account.description ?? 'Sem descrição'),
                              subtitle: Text(
                                'Vencimento: ${app_date_utils.DateUtils.formatDate(account.dueDate)}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyUtils.format(account.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
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
                                        ? Colors.green[100]
                                        : account.status == 'paid'
                                            ? Colors.blue[100]
                                            : Colors.red[100],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (order.isOpen)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cancelar Pedido'),
                          content: const Text(
                            'Tem certeza que deseja cancelar este pedido?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Não'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sim'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await OrderRepository().cancelOrder(orderId);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar Pedido'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erro: $error')),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}


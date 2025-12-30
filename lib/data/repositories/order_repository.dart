import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../../core/config/supabase_config.dart';

class OrderRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<OrderModel>> getOrders(String companyId, {String? status}) async {
    var query = _supabase
        .from('orders')
        .select()
        .eq('company_id', companyId);

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('order_date', ascending: false);
    return (response as List)
        .map((json) => OrderModel.fromJson(json))
        .toList();
  }

  Future<OrderModel> getOrder(String id) async {
    final response = await _supabase
        .from('orders')
        .select()
        .eq('id', id)
        .single();

    return OrderModel.fromJson(response);
  }

  Future<List<OrderItemModel>> getOrderItems(String orderId) async {
    final response = await _supabase
        .from('order_items')
        .select()
        .eq('order_id', orderId);

    return (response as List)
        .map((json) => OrderItemModel.fromJson(json))
        .toList();
  }

  Future<OrderModel> createOrder({
    required OrderModel order,
    required List<OrderItemModel> items,
    int? installmentsCount,
    int? installmentsIntervalDays,
  }) async {
    // Calcular total
    double total = 0.0;
    for (var item in items) {
      total += item.subtotal;
    }

    // Criar pedido
    final orderData = order.toJsonForInsert();
    orderData['total_amount'] = total;

    final orderResponse = await _supabase
        .from('orders')
        .insert(orderData)
        .select()
        .single();

    final createdOrder = OrderModel.fromJson(orderResponse);

    // Criar itens do pedido
    for (var item in items) {
      final itemData = item.toJsonForInsert();
      itemData['order_id'] = createdOrder.id;
      await _supabase.from('order_items').insert(itemData);
    }

    // Gerar contas a receber
    if (order.paymentType == 'cash') {
      // Pagamento à vista - cria uma conta a receber para hoje
      await _supabase.from('accounts_receivable').insert({
        'company_id': order.companyId,
        'order_id': createdOrder.id,
        'customer_id': order.customerId,
        'description': 'Pedido #${createdOrder.id.substring(0, 8)}',
        'due_date': DateTime.now().toIso8601String().split('T')[0],
        'amount': total,
        'status': 'open',
      });
    } else if (order.paymentType == 'installments' &&
        installmentsCount != null &&
        installmentsIntervalDays != null) {
      // Pagamento parcelado - cria múltiplas contas
      final installmentAmount = total / installmentsCount;
      final today = DateTime.now();

      for (int i = 0; i < installmentsCount; i++) {
        final dueDate = today.add(Duration(days: i * installmentsIntervalDays));
        await _supabase.from('accounts_receivable').insert({
          'company_id': order.companyId,
          'order_id': createdOrder.id,
          'customer_id': order.customerId,
          'description':
              'Pedido #${createdOrder.id.substring(0, 8)} - Parcela ${i + 1}/$installmentsCount',
          'due_date': dueDate.toIso8601String().split('T')[0],
          'amount': installmentAmount,
          'status': 'open',
        });
      }
    }

    return createdOrder;
  }

  Future<OrderModel> updateOrderStatus(String id, String status) async {
    final response = await _supabase
        .from('orders')
        .update({'status': status})
        .eq('id', id)
        .select()
        .single();

    return OrderModel.fromJson(response);
  }

  Future<void> cancelOrder(String id) async {
    // Não deleta, apenas marca como cancelado
    await _supabase
        .from('orders')
        .update({'status': 'canceled'})
        .eq('id', id);
  }
}


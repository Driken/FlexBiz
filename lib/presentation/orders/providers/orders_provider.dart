import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

final ordersProvider = FutureProvider.family<List<OrderModel>, String>(
  (ref, companyId) async {
    final repo = ref.read(orderRepositoryProvider);
    return await repo.getOrders(companyId);
  },
);

final orderDetailProvider =
    FutureProvider.family<OrderModel, String>((ref, orderId) async {
  final repo = ref.read(orderRepositoryProvider);
  return await repo.getOrder(orderId);
});


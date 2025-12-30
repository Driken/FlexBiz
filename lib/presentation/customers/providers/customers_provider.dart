import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final customersProvider = FutureProvider.family<List<CustomerModel>, String>(
  (ref, companyId) async {
    final repo = ref.read(customerRepositoryProvider);
    return await repo.getCustomers(companyId);
  },
);


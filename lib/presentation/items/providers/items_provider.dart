import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/item_model.dart';
import '../../../data/repositories/item_repository.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository();
});

final itemsProvider = FutureProvider.family<List<ItemModel>, String>(
  (ref, companyId) async {
    final repo = ref.read(itemRepositoryProvider);
    return await repo.getItems(companyId, isActive: null);
  },
);

final activeItemsProvider = FutureProvider.family<List<ItemModel>, String>(
  (ref, companyId) async {
    final repo = ref.read(itemRepositoryProvider);
    return await repo.getItems(companyId, isActive: true);
  },
);


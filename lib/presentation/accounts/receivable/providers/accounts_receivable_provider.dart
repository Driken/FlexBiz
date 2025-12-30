import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flexbiz/data/models/account_receivable_model.dart';
import 'package:flexbiz/data/repositories/account_receivable_repository.dart';

final accountReceivableRepositoryProvider =
    Provider<AccountReceivableRepository>((ref) {
  return AccountReceivableRepository();
});

final accountsReceivableProvider =
    FutureProvider.family<List<AccountReceivableModel>, String>(
  (ref, companyId) async {
    final repo = ref.read(accountReceivableRepositoryProvider);
    return await repo.getAccounts(companyId);
  },
);

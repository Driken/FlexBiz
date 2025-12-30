import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flexbiz/data/models/account_payable_model.dart';
import 'package:flexbiz/data/repositories/account_payable_repository.dart';

final accountPayableRepositoryProvider =
    Provider<AccountPayableRepository>((ref) {
  return AccountPayableRepository();
});

final accountsPayableProvider =
    FutureProvider.family<List<AccountPayableModel>, String>(
  (ref, companyId) async {
    final repo = ref.read(accountPayableRepositoryProvider);
    return await repo.getAccounts(companyId);
  },
);


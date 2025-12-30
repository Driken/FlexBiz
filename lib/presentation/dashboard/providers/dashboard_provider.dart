import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/account_receivable_model.dart';
import '../../../data/repositories/account_receivable_repository.dart';
import '../../../data/repositories/account_payable_repository.dart';

final accountReceivableRepositoryProvider =
    Provider<AccountReceivableRepository>((ref) {
  return AccountReceivableRepository();
});

final accountPayableRepositoryProvider =
    Provider<AccountPayableRepository>((ref) {
  return AccountPayableRepository();
});

class DashboardData {
  final double totalReceivableToday;
  final double totalPayableToday;
  final double totalReceivableMonth;
  final double totalPayableMonth;
  final double projectedBalance;

  DashboardData({
    required this.totalReceivableToday,
    required this.totalPayableToday,
    required this.totalReceivableMonth,
    required this.totalPayableMonth,
    required this.projectedBalance,
  });
}

final dashboardProvider = FutureProvider.family<DashboardData, String>(
  (ref, companyId) async {
    final receivableRepo = ref.read(accountReceivableRepositoryProvider);
    final payableRepo = ref.read(accountPayableRepositoryProvider);

    final receivableToday = await receivableRepo.getTotalToday(companyId);
    final payableToday = await payableRepo.getTotalToday(companyId);
    final receivableMonth = await receivableRepo.getTotalMonth(companyId);
    final payableMonth = await payableRepo.getTotalMonth(companyId);

    return DashboardData(
      totalReceivableToday: receivableToday,
      totalPayableToday: payableToday,
      totalReceivableMonth: receivableMonth,
      totalPayableMonth: payableMonth,
      projectedBalance: receivableMonth - payableMonth,
    );
  },
);

final upcomingAccountsProvider =
    FutureProvider.family<List<AccountReceivableModel>, String>(
  (ref, companyId) async {
    final receivableRepo = ref.read(accountReceivableRepositoryProvider);
    return await receivableRepo.getUpcoming(companyId, days: 7);
  },
);


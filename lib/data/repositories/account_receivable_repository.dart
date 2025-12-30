import '../models/account_receivable_model.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/date_utils.dart';

class AccountReceivableRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<AccountReceivableModel>> getAccounts(
    String companyId, {
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabase
        .from('accounts_receivable')
        .select()
        .eq('company_id', companyId);

    if (status != null) {
      query = query.eq('status', status);
    }

    if (startDate != null) {
      query = query.gte('due_date', startDate.toIso8601String().split('T')[0]);
    }

    if (endDate != null) {
      query = query.lte('due_date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('due_date', ascending: true);
    return (response as List)
        .map((json) => AccountReceivableModel.fromJson(json))
        .toList();
  }

  Future<AccountReceivableModel> getAccount(String id) async {
    final response = await _supabase
        .from('accounts_receivable')
        .select()
        .eq('id', id)
        .single();

    return AccountReceivableModel.fromJson(response);
  }

  Future<double> getTotalToday(String companyId) async {
    final today = DateTime.now();
    final response = await _supabase
        .from('accounts_receivable')
        .select('amount')
        .eq('company_id', companyId)
        .eq('status', 'open')
        .eq('due_date', today.toIso8601String().split('T')[0]);

    if (response.isEmpty) return 0.0;

    double total = 0.0;
    for (var item in response) {
      total += (item['amount'] as num).toDouble();
    }
    return total;
  }

  Future<double> getTotalMonth(String companyId) async {
    final now = DateTime.now();
    final startOfMonth = DateUtils.startOfMonth(now);
    final endOfMonth = DateUtils.endOfMonth(now);

    final response = await _supabase
        .from('accounts_receivable')
        .select('amount')
        .eq('company_id', companyId)
        .eq('status', 'open')
        .gte('due_date', startOfMonth.toIso8601String().split('T')[0])
        .lte('due_date', endOfMonth.toIso8601String().split('T')[0]);

    if (response.isEmpty) return 0.0;

    double total = 0.0;
    for (var item in response) {
      total += (item['amount'] as num).toDouble();
    }
    return total;
  }

  Future<List<AccountReceivableModel>> getUpcoming(String companyId,
      {int days = 7}) async {
    final today = DateTime.now();
    final endDate = today.add(Duration(days: days));

    final response = await _supabase
        .from('accounts_receivable')
        .select()
        .eq('company_id', companyId)
        .eq('status', 'open')
        .gte('due_date', today.toIso8601String().split('T')[0])
        .lte('due_date', endDate.toIso8601String().split('T')[0])
        .order('due_date', ascending: true)
        .limit(10);

    return (response as List)
        .map((json) => AccountReceivableModel.fromJson(json))
        .toList();
  }

  Future<void> markAsPaid(String id, DateTime paymentDate) async {
    await _supabase
        .from('accounts_receivable')
        .update({
          'status': 'paid',
          'payment_date': paymentDate.toIso8601String().split('T')[0],
        })
        .eq('id', id);
  }

  Future<void> updateStatusToLate() async {
    // Atualiza contas vencidas para status 'late'
    final today = DateTime.now();
    await _supabase
        .from('accounts_receivable')
        .update({'status': 'late'})
        .eq('status', 'open')
        .lt('due_date', today.toIso8601String().split('T')[0]);
  }
}


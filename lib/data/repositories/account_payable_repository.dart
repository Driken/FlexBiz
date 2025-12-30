import '../models/account_payable_model.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/date_utils.dart';

class AccountPayableRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<AccountPayableModel>> getAccounts(
    String companyId, {
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _supabase
        .from('accounts_payable')
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
        .map((json) => AccountPayableModel.fromJson(json))
        .toList();
  }

  Future<AccountPayableModel> getAccount(String id) async {
    final response = await _supabase
        .from('accounts_payable')
        .select()
        .eq('id', id)
        .single();

    return AccountPayableModel.fromJson(response);
  }

  Future<AccountPayableModel> createAccount(AccountPayableModel account) async {
    final response = await _supabase
        .from('accounts_payable')
        .insert(account.toJsonForInsert())
        .select()
        .single();

    return AccountPayableModel.fromJson(response);
  }

  Future<AccountPayableModel> updateAccount(AccountPayableModel account) async {
    // No MVP, contas pagas não podem ter valor editado
    if (account.isPaid) {
      throw Exception('Contas pagas não podem ser editadas');
    }

    final response = await _supabase
        .from('accounts_payable')
        .update({
          'supplier_name': account.supplierName,
          'description': account.description,
          'due_date': account.dueDate?.toIso8601String().split('T')[0],
          'amount': account.amount,
        })
        .eq('id', account.id)
        .select()
        .single();

    return AccountPayableModel.fromJson(response);
  }

  Future<double> getTotalToday(String companyId) async {
    final today = DateTime.now();
    final response = await _supabase
        .from('accounts_payable')
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
        .from('accounts_payable')
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

  Future<void> markAsPaid(String id, DateTime paymentDate) async {
    await _supabase
        .from('accounts_payable')
        .update({
          'status': 'paid',
          'payment_date': paymentDate.toIso8601String().split('T')[0],
        })
        .eq('id', id);
  }

  Future<void> deleteAccount(String id) async {
    final account = await getAccount(id);
    if (account.isPaid) {
      throw Exception('Contas pagas não podem ser excluídas');
    }
    await _supabase.from('accounts_payable').delete().eq('id', id);
  }
}


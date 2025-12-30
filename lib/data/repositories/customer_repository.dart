import '../models/customer_model.dart';
import '../../core/config/supabase_config.dart';

class CustomerRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<CustomerModel>> getCustomers(String companyId) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('company_id', companyId)
        .order('name');

    return (response as List)
        .map((json) => CustomerModel.fromJson(json))
        .toList();
  }

  Future<CustomerModel> getCustomer(String id) async {
    final response = await _supabase
        .from('customers')
        .select()
        .eq('id', id)
        .single();

    return CustomerModel.fromJson(response);
  }

  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    final response = await _supabase
        .from('customers')
        .insert(customer.toJsonForInsert())
        .select()
        .single();

    return CustomerModel.fromJson(response);
  }

  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final response = await _supabase
        .from('customers')
        .update({
          'name': customer.name,
          'phone': customer.phone,
          'email': customer.email,
          'document': customer.document,
        })
        .eq('id', customer.id)
        .select()
        .single();

    return CustomerModel.fromJson(response);
  }

  Future<void> deleteCustomer(String id) async {
    await _supabase.from('customers').delete().eq('id', id);
  }

  Future<double> getTotalOpenAmount(String customerId) async {
    final response = await _supabase
        .from('accounts_receivable')
        .select('amount')
        .eq('customer_id', customerId)
        .eq('status', 'open');

    if (response.isEmpty) return 0.0;

    double total = 0.0;
    for (var item in response) {
      total += (item['amount'] as num).toDouble();
    }
    return total;
  }
}


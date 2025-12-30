import '../models/item_model.dart';
import '../../core/config/supabase_config.dart';

class ItemRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<ItemModel>> getItems(String companyId, {bool? isActive}) async {
    var query = _supabase
        .from('items')
        .select()
        .eq('company_id', companyId)
        .order('name');

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query;
    return (response as List)
        .map((json) => ItemModel.fromJson(json))
        .toList();
  }

  Future<ItemModel> getItem(String id) async {
    final response = await _supabase
        .from('items')
        .select()
        .eq('id', id)
        .single();

    return ItemModel.fromJson(response);
  }

  Future<ItemModel> createItem(ItemModel item) async {
    final response = await _supabase
        .from('items')
        .insert(item.toJsonForInsert())
        .select()
        .single();

    return ItemModel.fromJson(response);
  }

  Future<ItemModel> updateItem(ItemModel item) async {
    final response = await _supabase
        .from('items')
        .update({
          'name': item.name,
          'type': item.type,
          'price': item.price,
          'is_active': item.isActive,
        })
        .eq('id', item.id)
        .select()
        .single();

    return ItemModel.fromJson(response);
  }

  Future<void> deleteItem(String id) async {
    await _supabase.from('items').delete().eq('id', id);
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flexbiz/presentation/shared/widgets/app_drawer.dart';
import 'package:flexbiz/presentation/shared/providers/session_provider.dart';
import 'package:flexbiz/core/utils/currency_utils.dart';
import '../providers/items_provider.dart';
import 'item_form_dialog.dart';

class ItemsListScreen extends ConsumerStatefulWidget {
  const ItemsListScreen({super.key});

  @override
  ConsumerState<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends ConsumerState<ItemsListScreen> {
  bool _showOnlyActive = true;

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itens'),
        actions: [
          Switch(
            value: _showOnlyActive,
            onChanged: (value) {
              setState(() {
                _showOnlyActive = value;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Sessão não encontrada'));
          }

          final itemsAsync = _showOnlyActive
              ? ref.watch(activeItemsProvider(session.companyId))
              : ref.watch(itemsProvider(session.companyId));

          return itemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum item cadastrado',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no + para adicionar',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(itemsProvider(session.companyId));
                  ref.invalidate(activeItemsProvider(session.companyId));
                },
                child: ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            item.isProduct ? Icons.shopping_bag : Icons.build,
                          ),
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.type == 'product' ? 'Produto' : 'Serviço'}${item.price != null ? ' • ${CurrencyUtils.format(item.price!)}' : ''}',
                        ),
                        trailing: item.isActive
                            ? null
                            : Chip(
                                label: const Text('Inativo'),
                                backgroundColor: Colors.grey[300],
                              ),
                        onTap: () async {
                          final result = await ItemFormDialog.show(
                            context,
                            item: item,
                          );
                          if (result == true) {
                            ref.invalidate(itemsProvider(session.companyId));
                            ref.invalidate(activeItemsProvider(session.companyId));
                          }
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Erro: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erro: $error')),
      ),
      floatingActionButton: sessionAsync.when(
        data: (session) => session == null
            ? null
            : FloatingActionButton(
                onPressed: () async {
                  final result = await ItemFormDialog.show(context);
                  if (result == true) {
                    ref.invalidate(itemsProvider(session.companyId));
                    ref.invalidate(activeItemsProvider(session.companyId));
                  }
                },
                child: const Icon(Icons.add),
              ),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }
}


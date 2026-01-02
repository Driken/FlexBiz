import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_list_item.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/providers/session_provider.dart';
import '../../../core/utils/currency_utils.dart';
import '../providers/items_provider.dart';
import 'item_form_screen.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Itens'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Apenas ativos',
                  style: AppTypography.caption,
                ),
                Switch(
                  value: _showOnlyActive,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return Center(
              child: Text(
                'Sessão não encontrada',
                style: AppTypography.body,
              ),
            );
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
                        color: AppColors.textDisabled,
                      ),
                      const SizedBox(height: AppSpacing.blockSpacing),
                      Text(
                        'Nenhum item cadastrado',
                        style: AppTypography.subtitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Toque no + para adicionar',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
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
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return AppListItem(
                      title: item.name,
                      subtitle:
                          '${item.type == 'product' ? 'Produto' : 'Serviço'}${item.price != null ? ' • ${CurrencyUtils.format(item.price!)}' : ''}',
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Icon(
                          item.isProduct ? Icons.shopping_bag : Icons.build,
                          color: AppColors.primary,
                        ),
                      ),
                      trailing: item.isActive
                          ? null
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.textDisabled.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Inativo',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textDisabled,
                                ),
                              ),
                            ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemFormScreen(item: item),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Erro: $error',
                style: AppTypography.body.copyWith(color: AppColors.error),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Erro: $error',
            style: AppTypography.body.copyWith(color: AppColors.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ItemFormScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textInverse),
      ),
    );
  }
}


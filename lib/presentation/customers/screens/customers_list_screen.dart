import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_list_item.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/providers/session_provider.dart';
import '../providers/customers_provider.dart';
import '../screens/customer_form_screen.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/repositories/customer_repository.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() =>
      _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clientes'),
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

          final customersAsync =
              ref.watch(customersProvider(session.companyId));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: AppInput(
                  label: 'Buscar cliente',
                  controller: _searchController,
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              Expanded(
                child: customersAsync.when(
                  data: (customers) {
                    final searchTerm = _searchController.text.toLowerCase();
                    final filteredCustomers = searchTerm.isEmpty
                        ? customers
                        : customers.where((customer) {
                            return customer.name
                                    .toLowerCase()
                                    .contains(searchTerm) ||
                                (customer.email?.toLowerCase()
                                        .contains(searchTerm) ??
                                    false) ||
                                (customer.phone?.contains(searchTerm) ?? false);
                          }).toList();

                    if (filteredCustomers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: AppColors.textDisabled,
                            ),
                            const SizedBox(height: AppSpacing.blockSpacing),
                            Text(
                              searchTerm.isEmpty
                                  ? 'Nenhum cliente cadastrado'
                                  : 'Nenhum cliente encontrado',
                              style: AppTypography.subtitle,
                            ),
                            if (searchTerm.isEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Toque no + para adicionar',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(customersProvider(session.companyId));
                      },
                      child: ListView.builder(
                        itemCount: filteredCustomers.length,
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          return FutureBuilder<double>(
                            future: CustomerRepository()
                                .getTotalOpenAmount(customer.id),
                            builder: (context, snapshot) {
                              final totalOpen = snapshot.data ?? 0.0;
                              String subtitle = '';
                              if (customer.phone != null) {
                                subtitle += 'Tel: ${customer.phone}';
                              }
                              if (customer.email != null) {
                                if (subtitle.isNotEmpty) subtitle += '\n';
                                subtitle += 'Email: ${customer.email}';
                              }
                              if (totalOpen > 0) {
                                if (subtitle.isNotEmpty) subtitle += '\n';
                                subtitle +=
                                    'Total em aberto: ${CurrencyUtils.format(totalOpen)}';
                              }

                              return AppListItem(
                                title: customer.name,
                                subtitle: subtitle.isNotEmpty ? subtitle : null,
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primarySoft,
                                  child: Text(
                                    customer.name[0].toUpperCase(),
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                trailing: totalOpen > 0
                                    ? Text(
                                        CurrencyUtils.format(totalOpen),
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CustomerFormScreen(customer: customer),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      'Erro: $error',
                      style: AppTypography.body.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
              builder: (context) => const CustomerFormScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textInverse),
      ),
    );
  }
}


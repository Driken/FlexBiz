import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/providers/session_provider.dart';
import '../providers/customers_provider.dart';
import '../screens/customer_form_dialog.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/models/customer_model.dart';

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
      appBar: AppBar(
        title: const Text('Clientes'),
      ),
      drawer: const AppDrawer(),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Sessão não encontrada'));
          }

          final customersAsync =
              ref.watch(customersProvider(session.companyId));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar cliente',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
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
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchTerm.isEmpty
                                  ? 'Nenhum cliente cadastrado'
                                  : 'Nenhum cliente encontrado',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (searchTerm.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Toque no + para adicionar',
                                style: Theme.of(context).textTheme.bodyMedium,
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
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          return FutureBuilder<double>(
                            future: CustomerRepository()
                                .getTotalOpenAmount(customer.id),
                            builder: (context, snapshot) {
                              final totalOpen = snapshot.data ?? 0.0;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      customer.name[0].toUpperCase(),
                                    ),
                                  ),
                                  title: Text(customer.name),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (customer.phone != null)
                                        Text('Tel: ${customer.phone}'),
                                      if (customer.email != null)
                                        Text('Email: ${customer.email}'),
                                      if (totalOpen > 0)
                                        Text(
                                          'Total em aberto: ${CurrencyUtils.format(totalOpen)}',
                                          style: TextStyle(
                                            color: Colors.orange[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        final result = await CustomerFormDialog.show(
                                          context,
                                          customer: customer,
                                        );
                                        if (result == true) {
                                          ref.invalidate(customersProvider(session.companyId));
                                        }
                                      } else if (value == 'delete') {
                                        await _confirmDeleteCustomer(
                                          context,
                                          customer,
                                          session.companyId,
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text('Editar'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Excluir', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    final result = await CustomerFormDialog.show(
                                      context,
                                      customer: customer,
                                    );
                                    if (result == true) {
                                      ref.invalidate(customersProvider(session.companyId));
                                    }
                                  },
                                ),
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
                    child: Text('Erro: $error'),
                  ),
                ),
              ),
            ],
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
                  final result = await CustomerFormDialog.show(context);
                  if (result == true) {
                    ref.invalidate(customersProvider(session.companyId));
                  }
                },
                child: const Icon(Icons.add),
              ),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Future<void> _confirmDeleteCustomer(
    BuildContext context,
    CustomerModel customer,
    String companyId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tem certeza que deseja excluir este cliente?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta ação não pode ser desfeita.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = CustomerRepository();
        await repo.deleteCustomer(customer.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente excluído com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          ref.invalidate(customersProvider(companyId));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir cliente: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}


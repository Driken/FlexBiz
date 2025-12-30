import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CustomerFormScreen(customer: customer),
                                      ),
                                    );
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomerFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}


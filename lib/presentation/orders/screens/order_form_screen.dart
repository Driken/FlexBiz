import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/session_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../items/providers/items_provider.dart';
import '../../customers/screens/customer_form_screen.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_item_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../providers/orders_provider.dart';
import 'package:flexbiz/core/utils/currency_utils.dart';
import 'package:flexbiz/core/utils/date_utils.dart' as app_date_utils;

class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  int _currentStep = 0;
  CustomerModel? _selectedCustomer;
  final List<Map<String, dynamic>> _selectedItems = [];
  String? _paymentType;
  int _installmentsCount = 1;
  int _installmentsIntervalDays = 30;
  DateTime _orderDate = DateTime.now();

  double get _totalAmount {
    double total = 0.0;
    for (var item in _selectedItems) {
      total += item['subtotal'] as double;
    }
    return total;
  }

  Future<void> _handleSave() async {
    if (_selectedCustomer == null || _selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os dados do pedido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final session = ref.read(sessionProvider).value;
      if (session == null) {
        throw Exception('Sessão não encontrada');
      }

      final repo = OrderRepository();

      final order = OrderModel(
        id: '',
        companyId: session.companyId,
        customerId: _selectedCustomer!.id,
        orderDate: _orderDate,
        status: 'open',
        paymentType: _paymentType,
        createdAt: DateTime.now(),
      );

      final orderItems = _selectedItems.map((item) {
        return OrderItemModel(
          id: '',
          orderId: '',
          itemId: item['item_id'] as String,
          quantity: item['quantity'] as double,
          unitPrice: item['unit_price'] as double,
          subtotal: item['subtotal'] as double,
        );
      }).toList();

      await repo.createOrder(
        order: order,
        items: orderItems,
        installmentsCount:
            _paymentType == 'installments' ? _installmentsCount : null,
        installmentsIntervalDays:
            _paymentType == 'installments' ? _installmentsIntervalDays : null,
      );

      ref.invalidate(ordersProvider(session.companyId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Pedido'),
      ),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Sessão não encontrada'));
          }

          return Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() {
                  _currentStep++;
                });
              } else {
                _handleSave();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() {
                  _currentStep--;
                });
              } else {
                Navigator.pop(context);
              }
            },
            steps: [
              Step(
                title: const Text('Cliente'),
                content: _buildCustomerStep(session.companyId),
                isActive: _currentStep >= 0,
                state: _selectedCustomer != null
                    ? StepState.complete
                    : StepState.indexed,
              ),
              Step(
                title: const Text('Itens'),
                content: _buildItemsStep(session.companyId),
                isActive: _currentStep >= 1,
                state: _selectedItems.isNotEmpty
                    ? StepState.complete
                    : StepState.indexed,
              ),
              Step(
                title: const Text('Pagamento'),
                content: _buildPaymentStep(),
                isActive: _currentStep >= 2,
                state: _paymentType != null
                    ? StepState.complete
                    : StepState.indexed,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erro: $error')),
      ),
    );
  }

  Widget _buildCustomerStep(String companyId) {
    final customersAsync = ref.watch(customersProvider(companyId));

    return customersAsync.when(
      data: (customers) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedCustomer != null) ...[
              Card(
                color: Colors.green[50],
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(_selectedCustomer!.name[0].toUpperCase()),
                  ),
                  title: Text(_selectedCustomer!.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedCustomer = null;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerFormScreen(),
                  ),
                );
                if (result == true) {
                  ref.invalidate(customersProvider(companyId));
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Criar Novo Cliente'),
            ),
            const SizedBox(height: 16),
            const Text('Ou selecione um cliente existente:'),
            const SizedBox(height: 8),
            ...customers.map((customer) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(customer.name[0].toUpperCase()),
                  ),
                  title: Text(customer.name),
                  onTap: () {
                    setState(() {
                      _selectedCustomer = customer;
                    });
                  },
                  selected: _selectedCustomer?.id == customer.id,
                ),
              );
            }),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Erro: $error'),
    );
  }

  Widget _buildItemsStep(String companyId) {
    final itemsAsync = ref.watch(activeItemsProvider(companyId));

    return itemsAsync.when(
      data: (items) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._selectedItems.map((selectedItem) {
              final item = items.firstWhere(
                (i) => i.id == selectedItem['item_id'],
              );
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    '${selectedItem['quantity']} x ${CurrencyUtils.format(selectedItem['unit_price'])} = ${CurrencyUtils.format(selectedItem['subtotal'])}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _selectedItems.remove(selectedItem);
                      });
                    },
                  ),
                ),
              );
            }),
            const Divider(),
            ...items.map((item) {
              final isSelected = _selectedItems
                  .any((si) => si['item_id'] == item.id);
              if (isSelected) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    item.price != null
                        ? CurrencyUtils.format(item.price!)
                        : 'Preço não definido',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _showQuantityDialog(item);
                    },
                  ),
                ),
              );
            }),
            if (_selectedItems.isNotEmpty) ...[
              const Divider(),
              Text(
                'Total: ${CurrencyUtils.format(_totalAmount)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Erro: $error'),
    );
  }

  void _showQuantityDialog(ItemModel item) {
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController(
      text: item.price?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantidade',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Preço Unitário',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity =
                  double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 1.0;
              final price = double.tryParse(
                      priceController.text.replaceAll(',', '.')) ??
                  item.price ??
                  0.0;

              setState(() {
                _selectedItems.add({
                  'item_id': item.id,
                  'quantity': quantity,
                  'unit_price': price,
                  'subtotal': quantity * price,
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Resumo do Pedido',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_selectedCustomer != null)
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Cliente'),
                    trailing: Text(_selectedCustomer!.name),
                  ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Data do Pedido'),
                  trailing: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _orderDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _orderDate = date;
                        });
                      }
                    },
                    child: Text(app_date_utils.DateUtils.formatDate(_orderDate)),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: const Text('Total de Itens'),
                  trailing: Text('${_selectedItems.length}'),
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Valor Total'),
                  trailing: Text(
                    CurrencyUtils.format(_totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Forma de Pagamento',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        RadioListTile<String>(
          title: const Text('À Vista'),
          value: 'cash',
          groupValue: _paymentType,
          onChanged: (value) {
            setState(() {
              _paymentType = value;
            });
          },
        ),
        RadioListTile<String>(
          title: const Text('Parcelado'),
          value: 'installments',
          groupValue: _paymentType,
          onChanged: (value) {
            setState(() {
              _paymentType = value;
            });
          },
        ),
        if (_paymentType == 'installments') ...[
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Número de Parcelas',
            ),
            onChanged: (value) {
              setState(() {
                _installmentsCount = int.tryParse(value) ?? 1;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Intervalo entre Parcelas (dias)',
            ),
            onChanged: (value) {
              setState(() {
                _installmentsIntervalDays = int.tryParse(value) ?? 30;
              });
            },
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Valor por Parcela',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyUtils.format(_totalAmount / _installmentsCount),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}


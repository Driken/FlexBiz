import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/session_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../items/providers/items_provider.dart';
import '../../customers/screens/customer_form_dialog.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_item_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../providers/orders_provider.dart';
import 'package:flexbiz/core/utils/currency_utils.dart';
import 'package:flexbiz/core/utils/date_utils.dart' as app_date_utils;

// Cores do sistema
class OrderFormColors {
  static const Color primary = Color(0xFF3B82F6);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color background = Color(0xFFF9FAFB);
}

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
  final TextEditingController _customerSearchController = TextEditingController();
  final TextEditingController _itemSearchController = TextEditingController();
  List<CustomerModel> _filteredCustomers = [];
  List<ItemModel> _filteredItems = [];

  double get _totalAmount {
    double total = 0.0;
    for (var item in _selectedItems) {
      total += item['subtotal'] as double;
    }
    return total;
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _itemSearchController.dispose();
    super.dispose();
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
      backgroundColor: OrderFormColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OrderFormColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Novo Pedido',
          style: TextStyle(
            color: OrderFormColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Sessão não encontrada'));
          }

          return Row(
            children: [
              // Conteúdo principal
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stepper moderno
                        _ModernStepper(
                          currentStep: _currentStep,
                          steps: const ['Cliente', 'Itens', 'Pagamento'],
                        ),
                        const SizedBox(height: 40),
                        // Conteúdo do step atual
                        _buildStepContent(session.companyId),
                        const SizedBox(height: 40),
                        // Botões de navegação
                        _buildNavigationButtons(),
                      ],
                    ),
                  ),
                ),
              ),
              // Sidebar com resumo (sticky)
              Container(
                width: 380,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: OrderFormColors.border, width: 1),
                  ),
                ),
                child: _OrderSummarySidebar(
                  customer: _selectedCustomer,
                  items: _selectedItems,
                  totalAmount: _totalAmount,
                  orderDate: _orderDate,
                  onDateChanged: (date) {
                    setState(() => _orderDate = date);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erro: $error')),
      ),
    );
  }

  Widget _buildStepContent(String companyId) {
    switch (_currentStep) {
      case 0:
        return _buildCustomerStep(companyId);
      case 1:
        return _buildItemsStep(companyId);
      case 2:
        return _buildPaymentStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Botão Ghost (Voltar/Cancelar)
        TextButton(
          onPressed: _currentStep > 0
              ? () {
                  setState(() => _currentStep--);
                }
              : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _currentStep > 0 ? 'Voltar' : 'Cancelar',
            style: const TextStyle(
              color: OrderFormColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Botão Primary (Próximo/Finalizar)
        ElevatedButton(
          onPressed: _canProceed() ? _handleNextStep : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: OrderFormColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
            shadowColor: OrderFormColors.primary.withOpacity(0.3),
          ),
          child: Text(
            _currentStep < 2 ? 'Continuar' : 'Finalizar Pedido',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedCustomer != null;
      case 1:
        return _selectedItems.isNotEmpty;
      case 2:
        return _paymentType != null;
      default:
        return false;
    }
  }

  void _handleNextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _handleSave();
    }
  }

  Widget _buildCustomerStep(String companyId) {
    final customersAsync = ref.watch(customersProvider(companyId));

    return customersAsync.when(
      data: (customers) {
        // Atualizar lista filtrada quando clientes mudarem
        if (_filteredCustomers.isEmpty && customers.isNotEmpty) {
          _filteredCustomers = customers;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecione o Cliente',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: OrderFormColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha um cliente existente ou crie um novo',
              style: TextStyle(
                fontSize: 15,
                color: OrderFormColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            // Cliente selecionado
            if (_selectedCustomer != null) ...[
              _SelectedCustomerCard(
                customer: _selectedCustomer!,
                onRemove: () {
                  setState(() => _selectedCustomer = null);
                },
              ),
              const SizedBox(height: 24),
            ],
            // Combobox com busca
            _CustomerSearchCombobox(
              controller: _customerSearchController,
              customers: customers,
              filteredCustomers: _filteredCustomers,
              onSearchChanged: (query) {
                setState(() {
                  if (query.isEmpty) {
                    _filteredCustomers = customers;
                  } else {
                    _filteredCustomers = customers
                        .where((c) => c.name
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                        .toList();
                  }
                });
              },
              onCustomerSelected: (customer) {
                setState(() {
                  _selectedCustomer = customer;
                  _customerSearchController.clear();
                  _filteredCustomers = customers;
                });
              },
            ),
            const SizedBox(height: 16),
            // Botão criar novo cliente
            OutlinedButton.icon(
              onPressed: () async {
                final result = await CustomerFormDialog.show(context);
                if (result == true) {
                  ref.invalidate(customersProvider(companyId));
                }
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Criar Novo Cliente'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: const BorderSide(color: OrderFormColors.border),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Erro: $error'),
    );
  }

  Widget _buildItemsStep(String companyId) {
    final itemsAsync = ref.watch(activeItemsProvider(companyId));

    return itemsAsync.when(
      data: (items) {
        // Atualizar lista filtrada quando itens mudarem
        if (_filteredItems.isEmpty && items.isNotEmpty) {
          _filteredItems = items;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adicione os Itens',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: OrderFormColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione os produtos ou serviços para este pedido',
              style: TextStyle(
                fontSize: 15,
                color: OrderFormColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            // Itens selecionados
            if (_selectedItems.isNotEmpty) ...[
              ..._selectedItems.map((selectedItem) {
                final item = items.firstWhere(
                  (i) => i.id == selectedItem['item_id'],
                );
                return _SelectedItemCard(
                  item: item,
                  quantity: selectedItem['quantity'] as double,
                  unitPrice: selectedItem['unit_price'] as double,
                  subtotal: selectedItem['subtotal'] as double,
                  onQuantityChanged: (newQuantity) {
                    setState(() {
                      final index = _selectedItems.indexOf(selectedItem);
                      _selectedItems[index] = {
                        ...selectedItem,
                        'quantity': newQuantity,
                        'subtotal': newQuantity * selectedItem['unit_price'],
                      };
                    });
                  },
                  onRemove: () {
                    setState(() => _selectedItems.remove(selectedItem));
                  },
                );
              }),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
            ],
            // Busca de itens
            _ItemSearchCombobox(
              controller: _itemSearchController,
              items: items,
              filteredItems: _filteredItems,
              selectedItemIds: _selectedItems
                  .map((si) => si['item_id'] as String)
                  .toList(),
              onSearchChanged: (query) {
                setState(() {
                  if (query.isEmpty) {
                    _filteredItems = items;
                  } else {
                    _filteredItems = items
                        .where((i) => i.name
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                        .toList();
                  }
                });
              },
              onItemSelected: (item) {
                _addItemToOrder(item);
              },
            ),
            // Empty state se não houver itens
            if (items.isEmpty)
              _EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Nenhum item cadastrado',
                subtitle: 'Cadastre produtos ou serviços para começar a criar pedidos.',
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Erro: $error'),
    );
  }

  void _addItemToOrder(ItemModel item) {
    final price = item.price ?? 0.0;
    setState(() {
      _selectedItems.add({
        'item_id': item.id,
        'quantity': 1.0,
        'unit_price': price,
        'subtotal': price,
      });
    });
    _itemSearchController.clear();
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Forma de Pagamento',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: OrderFormColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Escolha como o cliente irá pagar',
          style: TextStyle(
            fontSize: 15,
            color: OrderFormColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        // Opções de pagamento
        _PaymentOptionCard(
          title: 'À Vista',
          subtitle: 'Pagamento único',
          icon: Icons.payment,
          value: 'cash',
          groupValue: _paymentType,
          onChanged: (value) {
            setState(() => _paymentType = value);
          },
        ),
        const SizedBox(height: 12),
        _PaymentOptionCard(
          title: 'Parcelado',
          subtitle: 'Dividido em várias parcelas',
          icon: Icons.credit_card,
          value: 'installments',
          groupValue: _paymentType,
          onChanged: (value) {
            setState(() => _paymentType = value);
          },
        ),
        // Configurações de parcelamento
        if (_paymentType == 'installments') ...[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OrderFormColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configurações de Parcelamento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: OrderFormColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                _ModernTextField(
                  label: 'Número de Parcelas',
                  initialValue: _installmentsCount.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _installmentsCount = int.tryParse(value) ?? 1;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _ModernTextField(
                  label: 'Intervalo entre Parcelas (dias)',
                  initialValue: _installmentsIntervalDays.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _installmentsIntervalDays = int.tryParse(value) ?? 30;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: OrderFormColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Valor por Parcela',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: OrderFormColors.textPrimary,
                        ),
                      ),
                      Text(
                        CurrencyUtils.format(_totalAmount / _installmentsCount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: OrderFormColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// Stepper moderno
class _ModernStepper extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const _ModernStepper({
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    // Círculo do step
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? OrderFormColors.success
                            : isActive
                                ? OrderFormColors.primary
                                : OrderFormColors.border,
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : OrderFormColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive || isCompleted
                            ? OrderFormColors.textPrimary
                            : OrderFormColors.textSecondary.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Linha conectora
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [
                                OrderFormColors.success,
                                OrderFormColors.success,
                              ]
                            : [
                                isActive
                                    ? OrderFormColors.primary
                                    : OrderFormColors.border,
                                OrderFormColors.border,
                              ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// Combobox de busca de cliente
class _CustomerSearchCombobox extends StatefulWidget {
  final TextEditingController controller;
  final List<CustomerModel> customers;
  final List<CustomerModel> filteredCustomers;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CustomerModel> onCustomerSelected;

  const _CustomerSearchCombobox({
    required this.controller,
    required this.customers,
    required this.filteredCustomers,
    required this.onSearchChanged,
    required this.onCustomerSelected,
  });

  @override
  State<_CustomerSearchCombobox> createState() =>
      _CustomerSearchComboboxState();
}

class _CustomerSearchComboboxState extends State<_CustomerSearchCombobox> {
  bool _showDropdown = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModernTextField(
          controller: widget.controller,
          label: 'Buscar cliente',
          hint: 'Digite o nome do cliente...',
          prefixIcon: Icons.search,
          onChanged: (value) {
            widget.onSearchChanged(value);
            setState(() => _showDropdown = value.isNotEmpty);
          },
          onTap: () {
            if (widget.controller.text.isNotEmpty) {
              setState(() => _showDropdown = true);
            }
          },
        ),
        if (_showDropdown && widget.filteredCustomers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: OrderFormColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.filteredCustomers.length,
              itemBuilder: (context, index) {
                final customer = widget.filteredCustomers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: OrderFormColors.primary.withOpacity(0.1),
                    child: Text(
                      customer.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: OrderFormColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(customer.name),
                  onTap: () {
                    widget.onCustomerSelected(customer);
                    setState(() => _showDropdown = false);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

// Card de cliente selecionado
class _SelectedCustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onRemove;

  const _SelectedCustomerCard({
    required this.customer,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OrderFormColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: OrderFormColors.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: OrderFormColors.success,
            child: Text(
              customer.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: OrderFormColors.textPrimary,
                  ),
                ),
                const Text(
                  'Cliente selecionado',
                  style: TextStyle(
                    fontSize: 13,
                    color: OrderFormColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onRemove,
            color: OrderFormColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// Combobox de busca de itens
class _ItemSearchCombobox extends StatefulWidget {
  final TextEditingController controller;
  final List<ItemModel> items;
  final List<ItemModel> filteredItems;
  final List<String> selectedItemIds;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ItemModel> onItemSelected;

  const _ItemSearchCombobox({
    required this.controller,
    required this.items,
    required this.filteredItems,
    required this.selectedItemIds,
    required this.onSearchChanged,
    required this.onItemSelected,
  });

  @override
  State<_ItemSearchCombobox> createState() => _ItemSearchComboboxState();
}

class _ItemSearchComboboxState extends State<_ItemSearchCombobox> {
  bool _showDropdown = false;

  @override
  Widget build(BuildContext context) {
    final availableItems = widget.filteredItems
        .where((item) => !widget.selectedItemIds.contains(item.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModernTextField(
          controller: widget.controller,
          label: 'Buscar item',
          hint: 'Digite o nome do produto ou serviço...',
          prefixIcon: Icons.search,
          onChanged: (value) {
            widget.onSearchChanged(value);
            setState(() => _showDropdown = value.isNotEmpty);
          },
          onTap: () {
            if (widget.controller.text.isNotEmpty) {
              setState(() => _showDropdown = true);
            }
          },
        ),
        if (_showDropdown && availableItems.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: OrderFormColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableItems.length,
              itemBuilder: (context, index) {
                final item = availableItems[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: OrderFormColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: OrderFormColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: item.price != null
                      ? Text(CurrencyUtils.format(item.price!))
                      : null,
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () {
                    widget.onItemSelected(item);
                    setState(() => _showDropdown = false);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

// Card de item selecionado com botões +/-
class _SelectedItemCard extends StatelessWidget {
  final ItemModel item;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  const _SelectedItemCard({
    required this.item,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OrderFormColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail/Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: OrderFormColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2,
              color: OrderFormColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Informações do item
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: OrderFormColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyUtils.format(unitPrice),
                  style: TextStyle(
                    fontSize: 14,
                    color: OrderFormColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Controles de quantidade
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: OrderFormColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: quantity > 1
                      ? () => onQuantityChanged(quantity - 1)
                      : null,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    quantity.toStringAsFixed(quantity.truncateToDouble() == quantity
                        ? 0
                        : 2),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: OrderFormColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => onQuantityChanged(quantity + 1),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Subtotal
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyUtils.format(subtotal),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: OrderFormColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Remover'),
                style: TextButton.styleFrom(
                  foregroundColor: OrderFormColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Card de opção de pagamento
class _PaymentOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = groupValue == value;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? OrderFormColors.primary
                : OrderFormColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? OrderFormColors.primary.withOpacity(0.1)
                    : OrderFormColors.border.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? OrderFormColors.primary
                    : OrderFormColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? OrderFormColors.primary
                          : OrderFormColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: OrderFormColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: OrderFormColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// Campo de texto moderno
class _ModernTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const _ModernTextField({
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.initialValue,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OrderFormColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: OrderFormColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: OrderFormColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}

// Sidebar com resumo do pedido (sticky)
class _OrderSummarySidebar extends StatelessWidget {
  final CustomerModel? customer;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final DateTime orderDate;
  final ValueChanged<DateTime> onDateChanged;

  const _OrderSummarySidebar({
    required this.customer,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo do Pedido',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: OrderFormColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            // Cliente
            if (customer != null) ...[
              _SummaryRow(
                label: 'Cliente',
                value: customer!.name,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
            ],
            // Data
            _SummaryRow(
              label: 'Data',
              value: app_date_utils.DateUtils.formatDate(orderDate),
              icon: Icons.calendar_today_outlined,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: orderDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  onDateChanged(date);
                }
              },
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            // Itens
            const Text(
              'Itens',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: OrderFormColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 48,
                        color: OrderFormColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum item adicionado',
                        style: TextStyle(
                          color: OrderFormColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item['quantity']}x Item',
                          style: TextStyle(
                            fontSize: 14,
                            color: OrderFormColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyUtils.format(item['subtotal'] as double),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: OrderFormColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: OrderFormColors.textPrimary,
                  ),
                ),
                Text(
                  CurrencyUtils.format(totalAmount),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: OrderFormColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Linha do resumo
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: OrderFormColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: OrderFormColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: OrderFormColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: OrderFormColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

// Empty state
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OrderFormColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: OrderFormColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: OrderFormColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: OrderFormColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

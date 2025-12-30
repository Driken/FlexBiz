import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../shared/providers/session_provider.dart';
import '../providers/customers_provider.dart';
import '../../shared/widgets/modal_form_dialog.dart';

class CustomerFormDialog extends ConsumerStatefulWidget {
  final CustomerModel? customer;

  const CustomerFormDialog({super.key, this.customer});

  @override
  ConsumerState<CustomerFormDialog> createState() => _CustomerFormDialogState();

  static Future<bool?> show(BuildContext context, {CustomerModel? customer}) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      builder: (context) => CustomerFormDialog(customer: customer),
    );
  }
}

class _CustomerFormDialogState extends ConsumerState<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _documentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone ?? '';
      _emailController.text = widget.customer!.email ?? '';
      _documentController.text = widget.customer!.document ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final session = ref.read(sessionProvider).value;
      if (session == null) {
        throw Exception('Sessão não encontrada');
      }

      final repo = CustomerRepository();

      if (widget.customer == null) {
        final newCustomer = CustomerModel(
          id: '',
          companyId: session.companyId,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          document: _documentController.text.trim().isEmpty
              ? null
              : _documentController.text.trim(),
          createdAt: DateTime.now(),
        );
        await repo.createCustomer(newCustomer);
      } else {
        final updatedCustomer = CustomerModel(
          id: widget.customer!.id,
          companyId: widget.customer!.companyId,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          document: _documentController.text.trim().isEmpty
              ? null
              : _documentController.text.trim(),
          createdAt: widget.customer!.createdAt,
        );
        await repo.updateCustomer(updatedCustomer);
      }

      ref.invalidate(customersProvider(session.companyId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.customer == null
                ? 'Cliente criado com sucesso!'
                : 'Cliente atualizado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalFormDialog(
      title: widget.customer == null ? 'Novo Cliente' : 'Editar Cliente',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o nome do cliente';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone (opcional)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail (opcional)',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && !value.contains('@')) {
                  return 'E-mail inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _documentController,
              decoration: const InputDecoration(
                labelText: 'CPF/CNPJ (opcional)',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.customer == null
                            ? 'Criar Cliente'
                            : 'Salvar Alterações'),
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


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flexbiz/data/models/account_payable_model.dart';
import 'package:flexbiz/data/repositories/account_payable_repository.dart';
import 'package:flexbiz/presentation/shared/providers/session_provider.dart';
import 'package:flexbiz/core/utils/date_utils.dart' as app_date_utils;
import '../providers/accounts_payable_provider.dart';
import 'package:flexbiz/presentation/shared/widgets/modal_form_dialog.dart';

class AccountPayableFormDialog extends ConsumerStatefulWidget {
  const AccountPayableFormDialog({super.key});

  @override
  ConsumerState<AccountPayableFormDialog> createState() =>
      _AccountPayableFormDialogState();

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      builder: (context) => const AccountPayableFormDialog(),
    );
  }
}

class _AccountPayableFormDialogState
    extends ConsumerState<AccountPayableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _supplierController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
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

      final repo = AccountPayableRepository();

      final amount = double.tryParse(
              _amountController.text.replaceAll(',', '.')) ??
          0.0;

      final account = AccountPayableModel(
        id: '',
        companyId: session.companyId,
        supplierName: _supplierController.text.trim().isEmpty
            ? null
            : _supplierController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dueDate: _dueDate,
        amount: amount,
        status: 'open',
        createdAt: DateTime.now(),
      );

      await repo.createAccount(account);

      ref.invalidate(accountsPayableProvider(session.companyId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta a pagar criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalFormDialog(
      title: 'Nova Conta a Pagar',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Fornecedor (opcional)',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor *',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o valor';
                }
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  return 'Valor inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Data de Vencimento'),
              subtitle: Text(
                _dueDate != null
                    ? app_date_utils.DateUtils.formatDate(_dueDate!)
                    : 'Selecione a data',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _dueDate = date;
                    });
                  }
                },
              ),
              contentPadding: EdgeInsets.zero,
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
                        : const Text('Criar Conta'),
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


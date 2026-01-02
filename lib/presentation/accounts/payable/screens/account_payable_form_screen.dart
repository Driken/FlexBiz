import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flexbiz/data/models/account_payable_model.dart';
import 'package:flexbiz/data/repositories/account_payable_repository.dart';
import 'package:flexbiz/core/utils/session_utils.dart';
import 'package:flexbiz/core/utils/date_utils.dart' as app_date_utils;
import '../providers/accounts_payable_provider.dart';

class AccountPayableFormScreen extends ConsumerStatefulWidget {
  const AccountPayableFormScreen({super.key});

  @override
  ConsumerState<AccountPayableFormScreen> createState() =>
      _AccountPayableFormScreenState();
}

class _AccountPayableFormScreenState
    extends ConsumerState<AccountPayableFormScreen> {
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

    setState(() {
      _isLoading = true;
    });

    try {
      final session = await getSessionSafely(ref);
      if (session == null) {
        throw Exception('Sessão não encontrada. Por favor, faça login novamente.');
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Conta a Pagar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Fornecedor (opcional)',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  prefixIcon: Icon(Icons.description),
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
                      ? app_date_utils.DateUtils.formatDate(_dueDate)
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
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Criar Conta a Pagar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


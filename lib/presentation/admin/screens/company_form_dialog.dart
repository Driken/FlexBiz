import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/company_repository.dart';
import '../../shared/widgets/modal_form_dialog.dart';

class CompanyFormDialog extends ConsumerStatefulWidget {
  const CompanyFormDialog({super.key});

  @override
  ConsumerState<CompanyFormDialog> createState() => _CompanyFormDialogState();

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      builder: (context) => const CompanyFormDialog(),
    );
  }
}

class _CompanyFormDialogState extends ConsumerState<CompanyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  bool _isLoading = false;

  final _companyRepository = CompanyRepository();

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _companyRepository.createCompany(
        name: _nameController.text.trim(),
        document: _documentController.text.trim().isEmpty
            ? null
            : _documentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Empresa criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar empresa: ${e.toString()}'),
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
      title: 'Cadastrar Empresa',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Empresa *',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o nome da empresa';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _documentController,
              decoration: const InputDecoration(
                labelText: 'CNPJ/CPF (opcional)',
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Cadastrar'),
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


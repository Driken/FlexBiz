import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/company_repository.dart';

class CompanyFormScreen extends ConsumerStatefulWidget {
  const CompanyFormScreen({super.key});

  @override
  ConsumerState<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends ConsumerState<CompanyFormScreen> {
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
        Navigator.pop(context, true); // Retorna true para indicar sucesso
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Empresa'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Empresa',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
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
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
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
                      : const Text('Cadastrar Empresa'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


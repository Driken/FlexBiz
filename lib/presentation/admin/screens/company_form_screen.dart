import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/repositories/company_repository.dart';
import '../../../data/models/company_model.dart';

class CompanyFormScreen extends ConsumerStatefulWidget {
  final CompanyModel? company;

  const CompanyFormScreen({super.key, this.company});

  @override
  ConsumerState<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends ConsumerState<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  bool _isLoading = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    if (widget.company != null) {
      _nameController.text = widget.company!.name;
      _documentController.text = widget.company!.document ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _nameError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = CompanyRepository();

      if (widget.company == null) {
        await repo.createCompany(
          name: _nameController.text.trim(),
          document: _documentController.text.trim().isEmpty
              ? null
              : _documentController.text.trim(),
        );
      } else {
        final updatedCompany = CompanyModel(
          id: widget.company!.id,
          name: _nameController.text.trim(),
          document: _documentController.text.trim().isEmpty
              ? null
              : _documentController.text.trim(),
          createdAt: widget.company!.createdAt,
        );
        await repo.updateCompany(updatedCompany);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.company == null
                ? 'Empresa criada com sucesso!'
                : 'Empresa atualizada com sucesso!'),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.company == null ? 'Nova Empresa' : 'Editar Empresa'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width < 600 ? 420 : 600,
              ),
              child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppInput(
                    label: 'Nome da Empresa',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.business),
                    hint: 'Digite o nome da empresa',
                    errorText: _nameError,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() {
                          _nameError = 'Digite o nome da empresa';
                        });
                        return '';
                      }
                      setState(() {
                        _nameError = null;
                      });
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.blockSpacing),
                  AppInput(
                    label: 'CNPJ/CPF (opcional)',
                    controller: _documentController,
                    prefixIcon: const Icon(Icons.badge),
                    hint: '00.000.000/0000-00',
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    text: widget.company == null
                        ? 'Criar Empresa'
                        : 'Salvar Alterações',
                    onPressed: _isLoading ? null : _handleSave,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppSpacing.blockSpacing),
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: AppTypography.body.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}


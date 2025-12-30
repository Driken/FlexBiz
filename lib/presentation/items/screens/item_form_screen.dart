import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/item_model.dart';
import '../../../data/repositories/item_repository.dart';
import '../../shared/providers/session_provider.dart';
import '../providers/items_provider.dart';
import '../../../core/utils/currency_utils.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  final ItemModel? item;

  const ItemFormScreen({super.key, this.item});

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _type = 'product';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _priceController.text =
          widget.item!.price != null ? widget.item!.price.toString() : '';
      _type = widget.item!.type;
      _isActive = widget.item!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final session = ref.read(sessionProvider).value;
      if (session == null) {
        throw Exception('Sessão não encontrada');
      }

      final repo = ItemRepository();
      final price = _priceController.text.isEmpty
          ? null
          : double.tryParse(_priceController.text.replaceAll(',', '.'));

      if (widget.item == null) {
        // Criar novo
        final newItem = ItemModel(
          id: '',
          companyId: session.companyId,
          name: _nameController.text.trim(),
          type: _type,
          price: price,
          isActive: _isActive,
          createdAt: DateTime.now(),
        );
        await repo.createItem(newItem);
      } else {
        // Atualizar existente
        final updatedItem = ItemModel(
          id: widget.item!.id,
          companyId: widget.item!.companyId,
          name: _nameController.text.trim(),
          type: _type,
          price: price,
          isActive: _isActive,
          createdAt: widget.item!.createdAt,
        );
        await repo.updateItem(updatedItem);
      }

      // Invalidar providers
      ref.invalidate(itemsProvider(session.companyId));
      ref.invalidate(activeItemsProvider(session.companyId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item == null
                ? 'Item criado com sucesso!'
                : 'Item atualizado com sucesso!'),
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
        title: Text(widget.item == null ? 'Novo Item' : 'Editar Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Item *',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o nome do item';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'product',
                    child: Text('Produto'),
                  ),
                  DropdownMenuItem(
                    value: 'service',
                    child: Text('Serviço'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _type = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Preço (opcional)',
                  prefixIcon: Icon(Icons.attach_money),
                  helperText: 'Use ponto ou vírgula como separador decimal',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final price = double.tryParse(value.replaceAll(',', '.'));
                    if (price == null || price < 0) {
                      return 'Preço inválido';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Item Ativo'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
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
                    : Text(widget.item == null ? 'Criar Item' : 'Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


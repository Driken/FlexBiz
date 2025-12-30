import 'package:flutter/material.dart';

/// Widget auxiliar para criar dialogs de formulário com fundo transparente
class ModalFormDialog extends StatelessWidget {
  final Widget child;
  final String title;
  final double? maxHeight;

  const ModalFormDialog({
    super.key,
    required this.child,
    required this.title,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    required String title,
    double? maxHeight,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: barrierDismissible,
      builder: (context) => ModalFormDialog(
        title: title,
        maxHeight: maxHeight,
        child: child,
      ),
    );
  }
}


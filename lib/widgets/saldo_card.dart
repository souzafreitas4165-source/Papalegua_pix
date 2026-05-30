import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:papaleguas_pix/widgets/secure_screen.dart';

/// Widget que exibe o saldo do usuário com opção de mostrar/ocultar
class SaldoCard extends StatelessWidget {
  final double saldo;
  final bool visivel;
  final bool isLoading;
  final String? error;
  final VoidCallback onToggleVisibilidade;

  const SaldoCard({
    super.key,
    required this.saldo,
    required this.visivel,
    required this.isLoading,
    this.error,
    required this.onToggleVisibilidade,
  });

  @override
  Widget build(BuildContext context) {
    return SecureScreen(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'R\$ ${visivel ? NumberFormat.currency(locale: 'pt_BR', symbol: '').format(saldo) : '•••••••'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      visivel ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: onToggleVisibilidade,
                  ),
                ],
              ),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (error != null)
                Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

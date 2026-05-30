import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransferDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transferencia;
  const TransferDetailScreen({super.key, required this.transferencia});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(transferencia['data'].toString());
    final formattedDate = date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(date)
        : transferencia['data'].toString();
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Transferência')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destinatário: ${transferencia['destinatario']}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Valor: R\$ ${transferencia['valor'].toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Data: $formattedDate', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            if (transferencia['status'] != null)
              Text('Status: ${transferencia['status']}',
                  style: const TextStyle(fontSize: 18)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.repeat),
                  label: const Text('Repetir'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/transfer', arguments: {
                      'destinatario': transferencia['destinatario'],
                      'valor': transferencia['valor'],
                    });
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Compartilhar'),
                  onPressed: () {
                    if (!context.mounted) return;
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    if (!context.mounted) return;
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade de compartilhamento em breve!'),
                      ),
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

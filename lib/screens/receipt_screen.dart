import 'package:flutter/material.dart';

class ReceiptScreen extends StatelessWidget {
  final String destinatario;
  final double valorEmReais;
  final String moeda;
  final double valorOriginal;
  final String? data;
  const ReceiptScreen(
      {super.key,
      required this.destinatario,
      required this.valorEmReais,
      required this.moeda,
      required this.valorOriginal,
      this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprovante'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transferência realizada com sucesso!',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 24),
                Text('Destinatário: $destinatario'),
                Text(
                    'Valor convertido: R\$ ${valorEmReais.toStringAsFixed(2)}'),
                Text(
                    'Valor original: $moeda ${valorOriginal.toStringAsFixed(2)}'),
                if (data != null) Text('Data: $data'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Compartilhamento futuro
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Função de compartilhamento em breve!')),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Compartilhar'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

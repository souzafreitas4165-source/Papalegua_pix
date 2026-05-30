import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:papaleguas_pix/screens/transactions/pix_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;
  
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(transaction['data']?.toString() ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
    
    final isTransfer = transaction['tipo'] == 'transferencia' || 
                       transaction['tipo'] == 'pix';
    final isCredit = transaction['valor'] is num && transaction['valor'] > 0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isTransfer ? 'Detalhes da Transferência' : 'Detalhes da Transação'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com ícone e valor
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCredit 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 32,
                      color: isCredit ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'R\$ ${(transaction['valor'] is num ? transaction['valor'].abs() : 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCredit ? 'Valor recebido' : 'Valor enviado',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Detalhes da transação
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow('Data', formattedDate),
                    const Divider(),
                    if (transaction['descricao'] != null) ...[
                      _buildDetailRow('Descrição', transaction['descricao']),
                      const Divider(),
                    ],
                    if (transaction['destinatario'] != null)
                      _buildDetailRow(
                        isCredit ? 'Remetente' : 'Destinatário', 
                        transaction['destinatario']
                      ),
                    if (transaction['codigo_transacao'] != null) ...[
                      const Divider(),
                      _buildDetailRow('Código', transaction['codigo_transacao']),
                    ],
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Botões de ação
            if (isTransfer) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.repeat),
                      label: const Text('Repetir'),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PixScreen(),
                            settings: RouteSettings(
                              arguments: {
                                'destinatario': transaction['destinatario'],
                                'valor': transaction['valor']?.abs(),
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Compartilhar'),
                      onPressed: () {
                        // TODO: Implementar compartilhamento
                        final snackBar = SnackBar(
                          content: const Text('Funcionalidade de compartilhamento em breve!'),
                          action: SnackBarAction(
                            label: 'OK',
                            onPressed: () {},
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

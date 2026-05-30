import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class NewReceiptScreen extends StatelessWidget {
  final String destinatario;
  final double valorEmReais;
  final String moeda;
  final double valorOriginal;
  final String? data;
  final String? descricao;
  final String? idTransacao;

  const NewReceiptScreen({
    super.key,
    required this.destinatario,
    required this.valorEmReais,
    required this.moeda,
    required this.valorOriginal,
    this.data,
    this.descricao,
    this.idTransacao,
  });

  String _getMoedaFormatada() {
    switch (moeda) {
      case 'BRL':
        return 'Real Brasileiro (BRL)';
      case 'USD':
        return 'Dólar Americano (USD)';
      case 'EUR':
        return 'Euro (EUR)';
      default:
        return moeda;
    }
  }

  String _getMoedaSimbolo() {
    switch (moeda) {
      case 'BRL':
        return 'R\$';
      case 'USD':
        return 'US\$';
      case 'EUR':
        return '€';
      default:
        return moeda;
    }
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: style ?? const TextStyle(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionDetailRow(String label, String value, String subtext, {bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: isTotal ? Colors.blue.shade50 : null,
        borderRadius: BorderRadius.circular(8.0),
        border: isTotal ? Border.all(color: Colors.blue.shade100) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isTotal ? Colors.blue.shade800 : Colors.grey.shade700,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 12,
                  color: isTotal ? Colors.blue.shade600 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue.shade900 : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReceipt() async {
    final dataFormatada = data ?? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final shareText = '''
💰 *Comprovante de Transferência* 💰

✅ *Transferência realizada com sucesso!*

📋 *Detalhes da Transação*
🔹 ID: ${idTransacao ?? 'N/A'}
🔹 Data: $dataFormatada

👤 *Destinatário*
$destinatario

💵 *Valor da Transferência*
${_getMoedaSimbolo()} ${valorOriginal.toStringAsFixed(2)} ($moeda)

💱 *Valor em Reais*
R\$ ${valorEmReais.toStringAsFixed(2)}

${descricao != null ? '📝 *Descrição*\n$descricao\n' : ''}
_Enviado via Papaleguas Pix_''';

    await SharePlus.instance.share(ShareParams(text: shareText));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dataFormatada = data ?? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprovante'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReceipt,
            tooltip: 'Compartilhar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Cabeçalho com ícone de sucesso
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Transferência realizada\ncom sucesso!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dataFormatada,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Card de resumo
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Valor', formatter.format(valorEmReais)),
                    const Divider(height: 24),
                    _buildInfoRow('Destinatário', destinatario),
                    if (descricao != null && descricao!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildInfoRow('Descrição', descricao!),
                    ],
                    const Divider(height: 24),
                    _buildInfoRow('ID da Transação', idTransacao ?? 'N/A',
                        style: const TextStyle(fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),

            // Detalhes da conversão (se moeda estrangeira)
            if (moeda != 'BRL')
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalhes da Conversão',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildConversionDetailRow(
                        'Valor original',
                        '${_getMoedaSimbolo()} ${valorOriginal.toStringAsFixed(2)}',
                        _getMoedaFormatada(),
                      ),
                      const SizedBox(height: 8),
                      _buildConversionDetailRow(
                        'Taxa de câmbio',
                        '1 $moeda = R\$ ${(valorEmReais / valorOriginal).toStringAsFixed(4)}',
                        'Taxa do dia',
                      ),
                      const SizedBox(height: 8),
                      _buildConversionDetailRow(
                        'Valor convertido',
                        formatter.format(valorEmReais),
                        'Real Brasileiro (BRL)',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),

            // Ações
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (context.mounted) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Início'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('Nova Transferência'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Rodapé informativo
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
              child: Text(
                'Este comprovante não é um documento fiscal.\nGuarde-o para sua referência.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

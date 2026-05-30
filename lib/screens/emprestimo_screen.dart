import 'package:flutter/material.dart';

class EmprestimoScreen extends StatefulWidget {
  const EmprestimoScreen({super.key});
  @override
  State<EmprestimoScreen> createState() => _EmprestimoScreenState();
}

class _EmprestimoScreenState extends State<EmprestimoScreen> {
  double _valor = 500;
  int _parcelas = 12;
  bool _aprovado = false;

  double get _juros => _valor * 9.99 * _parcelas;
  double get _total => _valor + _juros;
  double get _parcela => _total / _parcelas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💸 Empréstimo do Vagabundo'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00FF6A).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('🦅 Bem-vindo ao Empréstimo do Vagabundo!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00FF6A)), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Crédito rápido, juros honestos*\n*honestos para nós', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Quanto você precisa?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Slider(
              value: _valor,
              min: 100,
              max: 5000,
              divisions: 49,
              activeColor: const Color(0xFF00FF6A),
              label: 'R\$ ${_valor.toStringAsFixed(0)}',
              onChanged: (v) => setState(() => _valor = v),
            ),
            Center(child: Text('R\$ ${_valor.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00FF6A)))),
            const SizedBox(height: 16),
            const Text('Parcelas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Slider(
              value: _parcelas.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              activeColor: const Color(0xFF00FF6A),
              label: '$_parcelas x',
              onChanged: (v) => setState(() => _parcelas = v.toInt()),
            ),
            Center(child: Text('$_parcelas parcelas', style: const TextStyle(fontSize: 18, color: Color(0xFF00FF6A)))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00FF6A).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('Resumo do Empréstimo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00FF6A))),
                  const Divider(color: Color(0xFF333333)),
                  _infoRow('Valor solicitado', 'R\$ ${_valor.toStringAsFixed(2)}'),
                  _infoRow('Juros (999% ao mês 😅)', 'R\$ ${_juros.toStringAsFixed(2)}', color: Colors.red),
                  _infoRow('Total a pagar', 'R\$ ${_total.toStringAsFixed(2)}', color: Colors.red),
                  _infoRow('Parcela mensal', 'R\$ ${_parcela.toStringAsFixed(2)}'),
                  _infoRow('Prazo de pagamento', 'Ontem'),
                  _infoRow('Garantia', 'Seu rim esquerdo'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!_aprovado)
              ElevatedButton(
                onPressed: () => setState(() => _aprovado = true),
                child: const Text('SOLICITAR EMPRÉSTIMO'),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF6A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00FF6A)),
                ),
                child: Column(
                  children: [
                    const Text('✅ APROVADO!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00FF6A))),
                    const SizedBox(height: 8),
                    const Text('Parabéns! Seu empréstimo foi aprovado!\n\nO Seu Zé passará na sua casa amanhã para combinar os detalhes. 😅', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fugir agora', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.white)),
        ],
      ),
    );
  }
}

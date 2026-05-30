import 'package:flutter/material.dart';
import 'package:papaleguas_pix/services/api_service.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  bool _cardVisible = false;
  final String _cardNumber = '**** **** **** 4242';
  final String _cardNumberFull = '5432 1234 5678 4242';
  final String _cardHolder = 'PAPALEGUAS PIX USER';
  final String _cardExpiry = '12/28';
  final String _cardCvv = '737';
  double _limit = 5000.00;
  double _used = 1234.56;

  @override
  Widget build(BuildContext context) {
    final available = _limit - _used;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartão de Crédito'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card visual
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF6A).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PAPALEGUAS PIX',
                          style: TextStyle(
                            color: Color(0xFF00FF6A),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const Icon(Icons.credit_card, color: Color(0xFF00FF6A), size: 32),
                      ],
                    ),
                    Text(
                      _cardVisible ? _cardNumberFull : _cardNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TITULAR', style: TextStyle(color: Color(0xFF888888), fontSize: 10)),
                            Text(_cardHolder, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('VALIDADE', style: TextStyle(color: Color(0xFF888888), fontSize: 10)),
                            Text(_cardExpiry, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CVV', style: TextStyle(color: Color(0xFF888888), fontSize: 10)),
                            Text(_cardVisible ? _cardCvv : '***', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Show/hide card button
            TextButton.icon(
              onPressed: () => setState(() => _cardVisible = !_cardVisible),
              icon: Icon(_cardVisible ? Icons.visibility_off : Icons.visibility),
              label: Text(_cardVisible ? 'Ocultar dados' : 'Ver dados do cartão'),
            ),
            const SizedBox(height: 24),
            // Limit info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00FF6A).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Limite do cartão', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Limite total', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                          Text('R\$ ${_limit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Utilizado', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                          Text('R\$ ${_used.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF3B30))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Disponível', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                          Text('R\$ ${available.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00FF6A))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _used / _limit,
                      backgroundColor: const Color(0xFF333333),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FF6A)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.lock,
                    label: 'Bloquear',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cartão bloqueado temporariamente!')),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.contactless,
                    label: 'NFC',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('NFC ativado!')),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.receipt_long,
                    label: 'Fatura',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fatura: R\$ ${1234.56}')),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Recent transactions
            const Text('Últimas transações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...[
              {'desc': 'Mercado Livre', 'value': '-R\$ 299,90', 'date': '28/05'},
              {'desc': 'iFood', 'value': '-R\$ 45,80', 'date': '27/05'},
              {'desc': 'Netflix', 'value': '-R\$ 39,90', 'date': '25/05'},
              {'desc': 'Posto Shell', 'value': '-R\$ 180,00', 'date': '24/05'},
            ].map((t) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1A1A1A),
                child: const Icon(Icons.shopping_bag, color: Color(0xFF00FF6A), size: 18),
              ),
              title: Text(t['desc']!),
              subtitle: Text(t['date']!),
              trailing: Text(t['value']!, style: const TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00FF6A).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00FF6A), size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

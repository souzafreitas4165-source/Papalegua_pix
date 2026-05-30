import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar Conta'),
      ),
      body: const Center(
        child: Text('Tela de Pagamento'),
      ),
    );
  }
}

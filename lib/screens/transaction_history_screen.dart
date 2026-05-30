import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:papaleguas_pix/models/paginated_response.dart';
import 'package:papaleguas_pix/services/account_service.dart';
import 'package:papaleguas_pix/widgets/paginated_list_view.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String userId;

  const TransactionHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  TransactionHistoryScreenState createState() =>
      TransactionHistoryScreenState();
}

class TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final AccountService _accountService = AccountService();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Transações'),
        centerTitle: true,
      ),
      body: PaginatedListView<Map<String, dynamic>>(
        fetchItems: _fetchTransactions,
        itemBuilder: (transaction, index) {
          final isCredit = transaction['type'] == 'credit';
          final amount = (transaction['amount'] as num).toDouble();
          final date = DateTime.parse(transaction['created_at']).toLocal();

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isCredit
                    ? Colors.green.withOpacity(0.2) // ignore: deprecated_member_use
                    : Colors.red.withOpacity(0.2), // ignore: deprecated_member_use
                child: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                transaction['description'] ?? 'Transação',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_dateFormat.format(date)),
              trailing: Text(
                '${isCredit ? '+' : '-'} R\$ ${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isCredit ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
        emptyBuilder: () => const Center(
          child: Text('Nenhuma transação encontrada'),
        ),
        errorBuilder: (error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Erro ao carregar transações',
                  style: TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<PaginatedResponse<Map<String, dynamic>>> _fetchTransactions(int page) async {
    try {
      return await _accountService.getTransactionHistory(
        userId: widget.userId,
        page: page,
        limit: 10,
      );
    } catch (e) {
      debugPrint('Erro ao buscar transações: $e');
      rethrow;
    }
  }
}

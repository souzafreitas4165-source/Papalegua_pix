import 'package:flutter/material.dart';

class CurrencyCard extends StatelessWidget {
  final String currencyName;
  final String currencyCode;
  final String amount;
  final String convertedAmount;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const CurrencyCard({
    super.key,
    required this.currencyName,
    required this.currencyCode,
    required this.amount,
    required this.convertedAmount,
    required this.icon,
    this.color = Colors.blue,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RepaintBoundary(
      child: Card(
        key: key ?? ValueKey('$currencyCode-$amount'),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho com ícone e informações da moeda
              _buildHeader(theme),
              const SizedBox(height: 16),
              // Conteúdo (carregando ou valores)
              _buildContent(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        // Ícone circular
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha((color.a * 0.2 * 255).round()),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        // Nome e código da moeda
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currencyName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              currencyCode,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withAlpha((255 * 0.7).round()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Valor principal (ex: 1 USD = R$ 5,00)
        Text(
          amount,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        // Valor convertido (ex: 10.00 USD)
        Text(
          convertedAmount,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withAlpha((255 * 0.8).round()),
          ),
        ),
      ],
    );
  }
}

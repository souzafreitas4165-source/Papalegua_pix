import 'package:flutter_test/flutter_test.dart';
import 'package:urubu_do_pix_novo/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';

void main() {
  group('Filtro de transferências', () {
    final historico = [
      {'destinatario': 'João', 'valor': 100.0, 'data': '2024-05-01', 'tipo': 'Enviado'},
      {'destinatario': 'Maria', 'valor': 250.0, 'data': '2024-05-02', 'tipo': 'Recebido'},
      {'destinatario': 'José', 'valor': 50.0, 'data': '2024-05-03', 'tipo': 'Enviado'},
      {'destinatario': 'Ana', 'valor': 300.0, 'data': '2024-05-04', 'tipo': 'Recebido'},
    ];

    testWidgets('Filtra por destinatário', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DashboardScreen(saldo: 1000, historico: historico),
      ));
      // Simula busca por "Maria"
      await tester.enterText(find.byType(TextField).first, 'Maria');
      await tester.pumpAndSettle();
      expect(find.text('Para: Maria'), findsOneWidget);
      expect(find.text('Para: João'), findsNothing);
    });

    testWidgets('Filtra por tipo de transação', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DashboardScreen(saldo: 1000, historico: historico),
      ));
      
      // Encontrar o Dropdown de filtro de transações (segundo Dropdown)
      final dropdowns = find.byType(DropdownButton<String>);
      expect(dropdowns, findsWidgets, reason: 'Deveria haver pelo menos um Dropdown na tela');
      
      // Garantir que o Dropdown de filtro de transações esteja visível
      final dropdownFinder = dropdowns.at(1);
      await tester.ensureVisible(dropdownFinder);
      await tester.pumpAndSettle();
      
      // Abrir o Dropdown
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();
      
      // Verificar se o item "Recebido" está visível no Dropdown
      final recebidoFinder = find.text('Recebido');
      expect(recebidoFinder, findsOneWidget, reason: 'O item "Recebido" deve estar visível no Dropdown');
      
      // Clicar no item "Recebido"
      await tester.tap(recebidoFinder);
      await tester.pumpAndSettle();
      
      // Verificar se apenas as transações do tipo "Recebido" são exibidas
      expect(find.text('Para: Maria'), findsOneWidget);
      expect(find.text('Para: Ana'), findsOneWidget);
      expect(find.text('Para: João'), findsNothing);
      expect(find.text('Para: José'), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urubu_do_pix_novo/widgets/saldo_card.dart';

void main() {
  testWidgets('Exibe loading quando isLoading é true', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaldoCard(
            saldo: 1000.0,
            visivel: true,
            isLoading: true,
            onToggleVisibilidade: () {},
          ),
        ),
      ),
    );

    // Verifica se o CircularProgressIndicator está sendo exibido
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Verifica se o texto de saldo não está visível
    expect(find.text('R\$ 1000.00'), findsNothing);
  });

  testWidgets('Exibe mensagem de erro quando error não é nulo', (WidgetTester tester) async {
    const errorMessage = 'Erro ao carregar';
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaldoCard(
            saldo: 0,
            visivel: true,
            isLoading: false,
            error: errorMessage,
            onToggleVisibilidade: () {},
          ),
        ),
      ),
    );

    // Verifica se a mensagem de erro está sendo exibida
    expect(find.text(errorMessage), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('Exibe saldo formatado quando visivel é true', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaldoCard(
            saldo: 1234.56,
            visivel: true,
            isLoading: false,
            onToggleVisibilidade: () {},
          ),
        ),
      ),
    );

    // Verifica se o saldo formatado está visível
    expect(find.text('R\$ 1234.56'), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });

  testWidgets('Exibe máscara quando visivel é false', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaldoCard(
            saldo: 1234.56,
            visivel: false,
            isLoading: false,
            onToggleVisibilidade: () {},
          ),
        ),
      ),
    );

    // Verifica se a máscara está sendo exibida
    expect(find.text('••••••'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('Chama onToggleVisibilidade quando o botão é pressionado', (WidgetTester tester) async {
    bool toggled = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaldoCard(
            saldo: 1000.0,
            visivel: true,
            isLoading: false,
            onToggleVisibilidade: () {
              toggled = true;
            },
          ),
        ),
      ),
    );

    // Encontra e pressiona o botão de visibilidade
    await tester.tap(find.byIcon(Icons.visibility));
    
    // Verifica se a função foi chamada
    expect(toggled, isTrue);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:urubu_do_pix_novo/screens/home_screen.dart';
import 'package:urubu_do_pix_novo/services/api_service.dart';
import 'package:urubu_do_pix_novo/services/auth_service.dart';

// Importa os mocks gerados
import 'home_screen_test.mocks.dart';

// Gera os mocks necessários
@GenerateMocks([ApiService, AuthService])
void main() {
  // Inicializa os mocks
  late MockApiService mockApiService;
  late MockAuthService mockAuthService;
  
  // Cria uma instância dos mocks antes de cada teste
  setUp(() {
    // Configura o ambiente de teste
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Inicializa os mocks
    mockApiService = MockApiService();
    mockAuthService = MockAuthService();
    
    // Configura o mock padrão para evitar erros em testes que não configuram explicitamente
    when(mockApiService.fetchSaldo()).thenAnswer((_) async => 0.0);
  });

  // Prepara o ambiente de teste com os providers necessários
  Future<void> pumpHomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // Injeta o ApiService mockado
          Provider<ApiService>.value(
            value: mockApiService,
          ),
          // Injeta o AuthService mockado usando ChangeNotifierProvider
          ChangeNotifierProvider<AuthService>.value(
            value: mockAuthService,
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => const HomeScreen(),
          ),
          // Adiciona rotas necessárias para testes de navegação
          routes: {
            '/login': (context) => const Scaffold(body: Center(child: Text('Login Screen'))),
          },
        ),
      ),
    );
    
    // Aguarda a conclusão das animações e carregamentos iniciais
    await tester.pumpAndSettle();
  }

  testWidgets('Exibe loading inicial', (WidgetTester tester) async {
    // Configura o mock para retornar um valor quando fetchSaldo for chamado
    when(mockApiService.fetchSaldo()).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return 1500.0;
    });
    
    // Executa o teste
    await pumpHomeScreen(tester);
    
    // Verifica se o indicador de carregamento está visível inicialmente
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Aguarda a conclusão do carregamento
    await tester.pumpAndSettle();
    
    // Verifica se o indicador de carregamento foi removido
    expect(find.byType(CircularProgressIndicator), findsNothing);
    
    // Verifica se o saldo está visível
    expect(find.text('R\$ 1500,00'), findsOneWidget);
  });

  testWidgets('Exibe saldo carregado', (WidgetTester tester) async {
    // Configura o mock para retornar um valor quando fetchSaldo for chamado
    when(mockApiService.fetchSaldo()).thenAnswer((_) async => 1500.0);
    
    // Executa o teste e aguarda a conclusão das animações
    await pumpHomeScreen(tester);
    await tester.pumpAndSettle();
    
    // Verifica se o saldo está sendo exibido corretamente
    expect(find.text('R\$ 1500,00'), findsOneWidget);
  });

  testWidgets('Exibe mensagem de erro', (WidgetTester tester) async {
    // Configura o mock para lançar uma exceção quando fetchSaldo for chamado
    when(mockApiService.fetchSaldo()).thenThrow(Exception('Erro de rede'));
    
    // Executa o teste e aguarda a conclusão das animações
    await pumpHomeScreen(tester);
    await tester.pumpAndSettle();
    
    // Verifica se a mensagem de erro está sendo exibida
    expect(find.text('Erro ao buscar saldo'), findsOneWidget);
  });

  testWidgets('Alterna visibilidade do saldo', (WidgetTester tester) async {
    // Configura o mock para retornar um valor quando fetchSaldo for chamado
    when(mockApiService.fetchSaldo()).thenAnswer((_) async => 1500.0);
    
    // Executa o teste e aguarda a conclusão das animações
    await pumpHomeScreen(tester);
    await tester.pumpAndSettle();
    
    // Verifica se o saldo está visível inicialmente
    expect(find.text('R\$ 1500,00'), findsOneWidget);
    
    // Clica no botão de alternar visibilidade
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();
    
    // Verifica se o saldo está oculto
    expect(find.text('••••••'), findsOneWidget);
    
    // Clica novamente para mostrar
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pumpAndSettle();
    
    // Verifica se o saldo está visível novamente
    expect(find.text('R\$ 1500,00'), findsOneWidget);
  });

  testWidgets('Navega para tela de transferência', (WidgetTester tester) async {
    // Configura o mock para retornar um valor quando fetchSaldo for chamado
    when(mockApiService.fetchSaldo()).thenAnswer((_) async => 1500.0);
    
    // Cria um GlobalKey para o Navigator
    final navigatorKey = GlobalKey<NavigatorState>();
    
    // Executa o teste com um MaterialApp que tem a rota de transferência
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: mockApiService),
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const HomeScreen(),
          routes: {
            '/transfer': (context) => const Scaffold(body: Center(child: Text('Transfer Screen'))),
          },
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Clica no botão de transferir
    await tester.tap(find.text('Transferir'));
    await tester.pumpAndSettle();
    
    // Verifica se a navegação ocorreu
    expect(find.text('Transfer Screen'), findsOneWidget);
  });

  testWidgets('Faz logout corretamente', (WidgetTester tester) async {
    // Cria um GlobalKey para o Navigator
    final navigatorKey = GlobalKey<NavigatorState>();
    
    // Configura os mocks
    when(mockApiService.fetchSaldo()).thenAnswer((_) async => 1500.0);
    
    // Cria um Completer para controlar quando o logout for concluído
    final logoutCompleter = Completer<void>();
    
    // Configura o mock para o logout
    when(mockAuthService.logout()).thenAnswer((_) async {
      // Simula o redirecionamento para a tela de login após logout
      navigatorKey.currentState?.pushReplacementNamed('/login');
      logoutCompleter.complete();
    });
    
    // Executa o teste com o MaterialApp que usa a navigatorKey
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: mockApiService),
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const HomeScreen(),
          routes: {
            '/login': (context) => const Scaffold(body: Center(child: Text('Login Screen'))),
          },
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Abre o drawer
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    
    // Clica em sair
    await tester.tap(find.text('Sair'));
    
    // Aguarda o logout ser concluído
    await logoutCompleter.future;
    await tester.pumpAndSettle();
    
    // Verifica se o método de logout foi chamado
    verify(mockAuthService.logout()).called(1);
    
    // Aguarda um pouco para a navegação ser concluída
    await tester.pumpAndSettle(const Duration(seconds: 1));
    
    // Verifica se a navegação para a tela de login ocorreu
    expect(find.text('Login Screen'), findsOneWidget);
  });
}

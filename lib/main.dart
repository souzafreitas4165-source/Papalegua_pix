import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:papaleguas_pix/config/supabase_config.dart';

import 'package:papaleguas_pix/services/auth_service.dart';
import 'package:papaleguas_pix/services/connectivity_service.dart';
import 'package:papaleguas_pix/services/app_state_manager.dart';
import 'package:papaleguas_pix/screens/home_screen.dart';
import 'package:papaleguas_pix/screens/login_screen.dart';
import 'package:papaleguas_pix/screens/register_screen.dart';
import 'package:papaleguas_pix/screens/profile_screen.dart';
import 'package:papaleguas_pix/screens/settings_screen.dart';
import 'package:papaleguas_pix/screens/card_screen.dart';
import 'package:papaleguas_pix/screens/emprestimo_screen.dart';
import 'package:papaleguas_pix/theme/app_theme.dart' show AppTheme;

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Navegando para: ${route.settings.name}');
    debugPrint('Rota anterior: ${previousRoute?.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Voltando de: ${route.settings.name}');
    debugPrint('Retornando para: ${previousRoute?.settings.name}');
  }
}

Future<void> main() async {
  // Configuração de logging
  Logger.root.level = Level.ALL; // Nível mais baixo para capturar todos os logs
  Logger.root.onRecord.listen((record) {
    debugPrint(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    if (record.error != null) {
      debugPrint('Erro: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('Stack trace: ${record.stackTrace}');
    }
  });

  // Inicializa o binding do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa serviços
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  // Ignora erros do flutter_secure para depuração
  try {
    const MethodChannel('flutter_secure')
        .setMethodCallHandler((MethodCall call) async {});
  } catch (e) {
    debugPrint('Aviso: flutter_secure não está disponível para depuração');
  }

  // Inicializa o Supabase usando a classe de configuração
  try {
    await SupabaseConfig.initialize();
    debugPrint('Supabase inicializado com sucesso');
  } catch (e, stackTrace) {
    debugPrint('Erro ao inicializar Supabase: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }

  // Executa o aplicativo com tratamento de erros global
  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stackTrace) {
      Logger('main').severe('Erro não tratado', error, stackTrace);
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    context.read<AppStateManager>().setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppStateManager _appStateManager;

  @override
  void initState() {
    super.initState();
    _appStateManager = AppStateManager();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    final connectivityService = ConnectivityService();
    connectivityService.connectionChangeController.stream.listen((isConnected) {
      _appStateManager.setOnlineStatus(isConnected);

      if (!isConnected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Você está offline. Algumas funções podem estar limitadas.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _appStateManager),
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider.value(value: ConnectivityService()),
      ],
      child: Consumer<AppStateManager>(
        builder: (context, appState, _) {
          return MaterialApp(
            navigatorObservers: [MyNavigatorObserver()],
            locale: appState.locale,
            onGenerateTitle: (context) =>
                Localizations.localeOf(context).languageCode == 'en'
                    ? 'Papaleguas Pix'
                    : 'Papaleguas Pix',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('pt', ''),
              Locale('en', ''),
            ],
            initialRoute: '/',
            routes: {
              '/': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/register': (context) => const RegisterScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/card': (context) => const CardScreen(),
              '/emprestimo': (context) => const EmprestimoScreen(),
            },
            builder: (context, child) {
              return Banner(
                location: BannerLocation.topEnd,
                message: appState.isOnline ? '' : 'OFFLINE',
                color: Colors.orange,
                child: child ?? const SizedBox(),
              );
            },
          );
        },
      ),
    );
  }
}

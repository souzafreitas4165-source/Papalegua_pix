import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:papaleguas_pix/services/api_service.dart';
import 'package:papaleguas_pix/services/app_state_manager.dart';
import 'package:papaleguas_pix/widgets/saldo_card.dart';
import 'package:papaleguas_pix/screens/dashboard_screen.dart';
import 'package:papaleguas_pix/screens/login_screen.dart';
import 'package:papaleguas_pix/screens/cotation_screen.dart';
import 'package:papaleguas_pix/screens/card_screen.dart';
import 'package:papaleguas_pix/screens/transfer_screen.dart';
import 'package:papaleguas_pix/screens/settings_screen.dart';
import 'package:papaleguas_pix/screens/emprestimo_screen.dart';
import 'package:papaleguas_pix/services/auth_service.dart';
import 'package:papaleguas_pix/main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _saldo = 0.0;
  bool _isLoading = true;
  String? _error;
  bool _saldoVisivel = true;
  String _nomeUsuario = 'Usuário';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchSaldo();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = ApiService().usuarioAtual;
      if (userId != null) {
        final userData = await ApiService().getUserProfile(userId);
        if (userData != null && userData['nome'] != null) {
          final nomeCompleto = userData['nome'] as String;
          final partesNome = nomeCompleto.split(' ');
          String nomeFormatado = nomeCompleto;
          if (partesNome.length > 1) {
            nomeFormatado = '${partesNome.first} ${partesNome.last}';
          }
          if (mounted) {
            setState(() {
              _nomeUsuario = nomeFormatado;
              _avatarUrl = userData['foto'] as String?;
            });
          }
          return;
        }
      }
      if (mounted) setState(() { _nomeUsuario = 'Usuário'; _avatarUrl = null; });
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
      if (mounted) setState(() => _nomeUsuario = 'Usuário');
    }
  }

  void _showSuccessSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _fetchSaldo() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final saldo = await ApiService().fetchSaldo();
      if (mounted) setState(() { _saldo = saldo; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Erro ao buscar saldo'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Papaleguas Pix')),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saldo disponível', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SaldoCard(
              saldo: _saldo,
              visivel: _saldoVisivel,
              isLoading: _isLoading,
              error: _error,
              onToggleVisibilidade: () => setState(() => _saldoVisivel = !_saldoVisivel),
            ),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 12),
            _buildEmprestimoButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmprestimoButton() {
    return Material(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EmprestimoScreen())),
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF00FF6A).withOpacity(0.4),
        highlightColor: const Color(0xFF00FF6A).withOpacity(0.2),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00FF6A).withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.money_off, color: Color(0xFF00FF6A), size: 26),
              SizedBox(width: 10),
              Text('💸 Empréstimo do Vagabundo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
            accountEmail: const Text(''),
            accountName: Text(_nomeUsuario, style: const TextStyle(color: Colors.white)),
            currentAccountPicture: _avatarUrl != null
                ? CircleAvatar(backgroundImage: NetworkImage(_avatarUrl!))
                : const CircleAvatar(child: Icon(Icons.person, size: 32)),
          ),
          _buildDrawerItem(icon: Icons.dashboard, title: 'Histórico', onTap: _navigateToDashboard),
          _buildThemeToggleItem(),
          _buildDrawerItem(icon: Icons.person, title: 'Perfil', onTap: () => _navigateTo('/profile')),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Configurações',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
          _buildLanguageItem(),
          _buildDrawerItem(icon: Icons.logout, title: 'Sair', onTap: _logout),
        ],
      ),
    );
  }

  Widget _buildThemeToggleItem() {
    return Consumer<AppStateManager>(
      builder: (context, appState, _) => ListTile(
        leading: const Icon(Icons.brightness_6),
        title: const Text('Tema'),
        onTap: appState.toggleTheme,
      ),
    );
  }

  Widget _buildLanguageItem() {
    return Consumer<AppStateManager>(
      builder: (context, appState, _) => ListTile(
        leading: const Icon(Icons.language),
        title: Text('Idioma: ${Localizations.localeOf(context).languageCode == 'en' ? 'Português' : 'English'}'),
        onTap: () {
          final locale = Localizations.localeOf(context).languageCode == 'pt'
              ? const Locale('en') : const Locale('pt');
          MyApp.setLocale(context, locale);
        },
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

  Widget _buildActionButtons() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildActionButton(text: 'Transferir', icon: Icons.pix, onPressed: _navigateToTransfer),
        _buildActionButton(
          text: 'Cotação',
          icon: Icons.currency_exchange,
          onPressed: () => Navigator.push(context, PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const CotationScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut))),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          )),
        ),
        _buildActionButton(text: 'Cartão', icon: Icons.credit_card, onPressed: () => Navigator.pushNamed(context, '/card')),
        _buildActionButton(text: 'Histórico', icon: Icons.history, onPressed: _navigateToDashboard),
      ],
    );
  }

  Widget _buildActionButton({required String text, required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF00FF6A).withOpacity(0.4),
        highlightColor: const Color(0xFF00FF6A).withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00FF6A).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF00FF6A), size: 22),
              const SizedBox(width: 8),
              Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToDashboard() async {
    Navigator.pop(context);
    final api = ApiService();
    try {
      final saldo = await api.fetchSaldo();
      final historico = await api.fetchHistorico();
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardScreen(saldo: saldo, historico: historico)));
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erro'),
          content: const Text('Você precisa estar logado para acessar o histórico.'),
          actions: [TextButton(onPressed: () { if (context.mounted) { Navigator.of(context).pop(); _navigateToLogin(); } }, child: const Text('OK'))],
        ),
      );
    }
  }

  Future<void> _navigateToTransfer() async {
    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    final result = await navigator.push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const TransferScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut))),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ));
    if (!context.mounted) return;
    await _fetchSaldo();
    if (result == true && context.mounted) _showSuccessSnackbar('Transferência realizada com sucesso!');
  }

  void _navigateTo(String route) {
    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    if (!context.mounted) return;
    navigator.pushNamed(route);
  }

  void _navigateToLogin() {
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  Future<void> _logout() async {
    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    if (!context.mounted) return;
    await context.read<AuthService>().logout();
    if (!context.mounted) return;
    _navigateToLogin();
  }
}

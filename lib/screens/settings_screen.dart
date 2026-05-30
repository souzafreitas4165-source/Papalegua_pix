import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:papaleguas_pix/services/biometric_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _biometricService = BiometricService();
  final _logger = Logger('SettingsScreen');
  
  bool _biometriaDisponivel = false;
  bool _biometriaHabilitada = false;
  bool _carregando = true;
  String _statusBiometria = 'Verificando...';

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  Future<void> _carregarConfiguracoes() async {
    try {
      setState(() => _statusBiometria = 'Verificando disponibilidade...');
      
      final disponivel = await _biometricService.isBiometricAvailable();
      final habilitada = await _biometricService.isBiometricEnabled();
      final temBiometriaCadastrada = await _biometricService.hasEnrolledBiometrics();
      
      if (mounted) {
        setState(() {
          _biometriaDisponivel = disponivel;
          _biometriaHabilitada = habilitada;
          _carregando = false;
          _statusBiometria = disponivel 
              ? (temBiometriaCadastrada 
                  ? 'Disponível' 
                  : 'Nenhuma biometria cadastrada')
              : 'Não disponível';
        });
      }
    } catch (e) {
      _logger.severe('Erro ao carregar configurações de biometria', e);
      if (mounted) {
        setState(() {
          _carregando = false;
          _statusBiometria = 'Erro ao verificar';
        });
      }
    }
  }

  Future<void> _toggleBiometria(bool value) async {
    try {
      setState(() => _carregando = true);
      
      if (value) {
        // Tenta autenticar antes de habilitar
        final autenticado = await _biometricService.authenticate(
          localizedReason: 'Autentique-se para habilitar a biometria',
        );
        
        if (!autenticado) {
          if (!mounted) return;
          _showSnackBar(
            'Autenticação biométrica necessária para habilitar',
            isError: true,
          );
          setState(() => _carregando = false);
          return;
        }
      }

      final sucesso = await _biometricService.setBiometricEnabled(value);
      
      if (mounted) {
        setState(() {
          _biometriaHabilitada = value && sucesso;
          _carregando = false;
        });
      }

      if (!mounted) return;
      
      if (sucesso) {
        _showSnackBar(
          value 
              ? 'Biometria habilitada com sucesso' 
              : 'Biometria desabilitada',
        );
      } else {
        _showSnackBar(
          'Não foi possível ${value ? 'habilitar' : 'desabilitar'} a biometria',
          isError: true,
        );
      }
      
      // Atualiza o status após a alteração
      await _carregarConfiguracoes();
      
    } catch (e) {
      _logger.severe('Erro ao alternar biometria', e);
      if (mounted) {
        setState(() => _carregando = false);
        _showSnackBar(
          'Erro ao configurar biometria: ${e.toString()}',
          isError: true,
        );
      }
    }
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Segurança',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_biometriaDisponivel) ...[
                  SwitchListTile(
                    title: const Text('Usar biometria'),
                    subtitle: Text(
                      _statusBiometria,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                    secondary: const Icon(Icons.fingerprint),
                    value: _biometriaHabilitada,
                    onChanged: _carregando 
                        ? null 
                        : _toggleBiometria,
                  ),
                  if (_carregando)
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                ] else
                  ListTile(
                    title: const Text('Biometria não disponível'),
                    subtitle: Text(
                      _statusBiometria,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    leading: Icon(
                      Icons.fingerprint_outlined,
                      color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                    ),
                  ),
                const Divider(),
              ],
            ),
    );
  }
}

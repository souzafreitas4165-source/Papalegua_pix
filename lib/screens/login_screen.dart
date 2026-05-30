import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:papaleguas_pix/services/biometric_service.dart';
import 'package:papaleguas_pix/services/api_service.dart';
import 'package:papaleguas_pix/screens/home_screen.dart';
import 'package:papaleguas_pix/screens/register_screen.dart';
import 'package:papaleguas_pix/routes/custom_route.dart';
import 'package:papaleguas_pix/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _biometricService = BiometricService();
  bool _biometriaDisponivel = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _senhaError;

  @override
  void initState() {
    super.initState();
    _verificarBiometria();
    
    // Adiciona listeners para validação em tempo real
    _emailController.addListener(_validateEmail);
    _senhaController.addListener(_validateSenha);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _senhaController.removeListener(_validateSenha);
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
  
  // Verifica se o formulário está válido
  bool get _isFormValid {
    return _emailController.text.isNotEmpty &&
           _emailError == null &&
           _senhaController.text.isNotEmpty &&
           _senhaError == null;
  }
  
  // Valida o campo de e-mail
  void _validateEmail() {
    setState(() {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = null;
        return;
      }
      
      if (!isValidEmail(email)) {
        _emailError = 'E-mail inválido';
      } else {
        _emailError = null;
      }
    });
  }
  
  // Valida o campo de senha
  void _validateSenha() {
    setState(() {
      if (_senhaController.text.isEmpty) {
        _senhaError = null;
        return;
      }
      
      if (_senhaController.text.length < 4) {
        _senhaError = 'A senha deve ter no mínimo 4 caracteres';
      } else {
        _senhaError = null;
      }
    });
  }

  Future<void> _verificarBiometria() async {
    final disponivel = await _biometricService.isBiometricAvailable();
    setState(() {
      _biometriaDisponivel = disponivel;
    });
  }

  Future<void> _autenticarComBiometria() async {
    final autenticado = await _biometricService.authenticate();
    if (autenticado && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _login() async {
    if (_isLoading || !_isFormValid) return;
    
    // Força a validação dos campos
    _validateEmail();
    _validateSenha();
    
    // Verifica se ainda há erros após a validação
    if (_emailError != null || _senhaError != null) {
      return;
    }
    
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final loginSucesso = await apiService.login(email, senha);
      
      if (!mounted) return;
      
      if (!loginSucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail/CPF ou senha incorretos'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      // Se chegou aqui, o login foi bem-sucedido
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login realizado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Aguarda um pouco para o usuário ver a mensagem antes de navegar
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      String mensagemErro = 'Erro ao fazer login. Tente novamente.';
      if (e is AuthException) {
        mensagemErro = e.message;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagemErro),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              
              // Logo e Título
              Column(
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: value,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              letterSpacing: 1.2,
                            ),
                            children: [
                              TextSpan(
                                text: 'PAPALEGUAS',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              TextSpan(
                                text: ' DO PIX',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rápido que nem Papaleguas! 🦅',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7 * 255),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),

              // Formulário de login
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título do formulário
                      Text(
                        'Acesse sua conta',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Faça login para continuar',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.7 * 255),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Campo de E-mail
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => _validateEmail(),
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(
                            Icons.email,
                            color: colorScheme.primary,
                          ),
                          errorText: _emailError,
                          errorStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _emailError != null 
                                  ? Colors.red 
                                  : colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _emailError != null 
                                  ? Colors.red 
                                  : colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo de senha
                      TextFormField(
                        controller: _senhaController,
                        obscureText: _obscurePassword,
                        onChanged: (_) => _validateSenha(),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(
                            Icons.lock,
                            color: colorScheme.primary,
                          ),
                          errorText: _senhaError,
                          errorStyle: const TextStyle(fontSize: 12),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: colorScheme.primary,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _senhaError != null 
                                  ? Colors.red 
                                  : colorScheme.primary.withValues(alpha: 0.5 * 255),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _senhaError != null ? Colors.red : colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botão de login
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (_isLoading || !_isFormValid) ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFormValid && !_isLoading 
                                ? colorScheme.primary 
                                : Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Entrar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _isFormValid ? Colors.white : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Link para cadastro
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            SlideRightRoute(
                              page: const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Ainda não tem conta? Cadastre-se',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Biometria com animação
              if (_biometriaDisponivel) ...[
                const SizedBox(height: 32),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: IconButton(
                          icon: Icon(
                            Icons.fingerprint,
                            size: 50,
                            color: colorScheme.primary,
                          ),
                          onPressed: _autenticarComBiometria,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entrar com biometria',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

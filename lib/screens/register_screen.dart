import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart' show MaskTextInputFormatter, MaskAutoCompletionType;
import 'package:papaleguas_pix/services/api_service.dart';
import 'package:papaleguas_pix/utils/validators.dart';
import 'package:papaleguas_pix/screens/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores para os campos de texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();

  // Formatadores para campos
  final maskPhone = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);
      
  final maskCpf = MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);

  // Variáveis de estado
  String? _errorMessage;
  String? _telefoneError, _nomeError, _emailError, _senhaError, _confirmarSenhaError, _cpfError;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _aceitouTermos = false;

  // Chave do formulário para validação
  final _formKey = GlobalKey<FormState>();

  // Verifica se todos os campos obrigatórios foram preenchidos corretamente
  bool get _isFormValid {
    return _emailController.text.isNotEmpty &&
           _emailError == null &&
           _senhaController.text.isNotEmpty &&
           _senhaError == null &&
           _confirmarSenhaController.text.isNotEmpty &&
           _confirmarSenhaError == null &&
           _nomeController.text.isNotEmpty &&
           _nomeError == null &&
           _telefoneController.text.isNotEmpty &&
           _telefoneError == null &&
           _cpfController.text.isNotEmpty &&
           _cpfError == null &&
           _aceitouTermos;
  }

  @override
  void initState() {
    super.initState();
    // Adiciona listeners para validação em tempo real
    _emailController.addListener(() {
      _validateEmail();
      setState(() {}); // Força a reconstrução para atualizar o estado do botão
    });
    _senhaController.addListener(() {
      _validateSenha();
      setState(() {});
    });
    _confirmarSenhaController.addListener(() {
      _validateConfirmarSenha();
      setState(() {});
    });
    _nomeController.addListener(() {
      _validateNome();
      setState(() {});
    });
    _telefoneController.addListener(() {
      _validateTelefone();
      setState(() {});
    });
    _cpfController.addListener(() {
      _validateCpf();
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Libera recursos
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  // Validação de e-mail em tempo real
  void _validateEmail() {
    setState(() {
      if (_emailController.text.isEmpty) {
        _emailError = null;
        return;
      }

      final text = _emailController.text.trim();
      if (!isValidEmail(text)) {
        _emailError = 'E-mail inválido';
      } else {
        _emailError = null;
      }
    });
  }

  void _validateSenha() {
    setState(() {
      if (_senhaController.text.isEmpty) {
        _senhaError = null;
        return;
      }

      if (!isStrongPassword(_senhaController.text)) {
        _senhaError =
            'A senha deve ter pelo menos 8 caracteres, incluindo letras maiúsculas, minúsculas, números e símbolos';
      } else {
        _senhaError = null;
      }

      // Valida a confirmação de senha se já foi preenchida
      if (_confirmarSenhaController.text.isNotEmpty) {
        _validateConfirmarSenha();
      }
    });
  }

  void _validateConfirmarSenha() {
    setState(() {
      if (_confirmarSenhaController.text.isEmpty) {
        _confirmarSenhaError = null;
        return;
      }

      if (_confirmarSenhaController.text != _senhaController.text) {
        _confirmarSenhaError = 'As senhas não coincidem';
      } else {
        _confirmarSenhaError = null;
      }
    });
  }

  void _validateNome() {
    setState(() {
      if (_nomeController.text.isEmpty) {
        _nomeError = null;
        return;
      }

      if (!isValidName(_nomeController.text)) {
        _nomeError = 'Digite nome e sobrenome válidos';
      } else {
        _nomeError = null;
      }
    });
  }

  void _validateTelefone() {
    setState(() {
      if (_telefoneController.text.isEmpty) {
        _telefoneError = null;
        return;
      }

      final phone = _telefoneController.text;
      if (phone.isEmpty) {
        _telefoneError = null;
        return;
      }
      
      final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cleaned.length != 11) {
        _telefoneError = 'O número deve ter 11 dígitos (DDD + 9 + número)';
      } else if (cleaned[2] != '9') {
        _telefoneError = 'Número de celular deve começar com 9 após o DDD';
      } else if (RegExp(r'^(\d)\1+$').hasMatch(cleaned.substring(2))) {
        _telefoneError = 'Número de telefone inválido';
      } else {
        _telefoneError = null;
      }
    });
  }
  
  void _validateCpf() {
    setState(() {
      if (_cpfController.text.isEmpty) {
        _cpfError = null;
        return;
      }
      
      final cpf = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cpf.length != 11) {
        _cpfError = 'CPF deve ter 11 dígitos';
      } else if (!isValidCPF(cpf)) {
        _cpfError = 'CPF inválido';
      } else {
        _cpfError = null;
      }
    });
  }

  void _register() async {
    // Valida todos os campos antes de enviar
    _validateEmail();
    _validateNome();
    _validateTelefone();
    _validateCpf();
    _validateSenha();
    _validateConfirmarSenha();

    // Verifica se há erros de validação
    if (_emailError != null ||
        _nomeError != null ||
        _telefoneError != null ||
        _cpfError != null ||
        _senhaError != null ||
        _confirmarSenhaError != null ||
        !_aceitouTermos) {
      setState(() {
        _errorMessage = 'Por favor, corrija os erros nos campos destacados.';
        if (!_aceitouTermos) {
          _errorMessage = 'É necessário aceitar os termos e condições.';
        }
      });
      return;
    }

    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final telefone = _telefoneController.text.trim();
    final nome = _nomeController.text.trim();
    final cpf = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mostra um indicador de progresso com mensagem
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Processando seu cadastro...'),
                const SizedBox(height: 8),
                Text('Aguarde enquanto verificamos seus dados',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          );
        },
      );

      // Realiza o cadastro
      debugPrint('Iniciando cadastro com os seguintes dados:');
      debugPrint('E-mail: $email');
      debugPrint('Nome: $nome');
      debugPrint('Telefone: $telefone');
      
      bool success = false;
      try {
        success = await ApiService().register(
          email,
          senha,
          nome: nome,
          telefone: telefone,
          cpf: cpf,
        );
      } catch (e, stackTrace) {
        debugPrint('Erro durante o cadastro: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }

      // Fecha o diálogo de progresso
      if (mounted && context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      if (success) {
        if (!context.mounted) return;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        if (!context.mounted) return;

        // Mostra mensagem de sucesso
        scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Cadastro realizado com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));

        // Redireciona para a tela inicial após um breve atraso
        await Future.delayed(const Duration(milliseconds: 700));
        if (!context.mounted) return;

        navigator.pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        if (!context.mounted) return;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        if (!context.mounted) return;

        // Mostra mensagem de erro
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('Este e-mail já está cadastrado.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ));
      }
    } catch (e) {
      // Fecha o diálogo de progresso se estiver aberto
      if (mounted && context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      
      String errorMessage = 'Erro ao processar o cadastro. Tente novamente.';
      
      // Log do erro completo para depuração
      debugPrint('Erro capturado: ${e.toString()}');
      
      // Log do erro completo para depuração
      final errorMessageStr = e.toString();
      final errorMessageLower = errorMessageStr.toLowerCase();
      debugPrint('Erro capturado: $errorMessageStr');
      
      // Tratamento de erros específicos
      if (errorMessageLower.contains('já existe um usuário cadastrado') ||
          errorMessageLower.contains('email already in use') ||
          errorMessageLower.contains('user already registered') ||
          errorMessageLower.contains('e-mail já cadastrado') ||
          errorMessageLower.contains('email já está em uso')) {
        errorMessage = 'Este e-mail já está cadastrado.';
        _emailError = 'E-mail já está em uso';
        debugPrint('Erro de e-mail duplicado tratado');
      } else if (errorMessageLower.contains('email') || 
                errorMessageLower.contains('e-mail') ||
                errorMessageLower.contains('usuário') ||
                errorMessageLower.contains('user')) {
        errorMessage = 'Erro ao processar o cadastro. Verifique os dados e tente novamente.';
        _emailError = 'Erro no e-mail';
        debugPrint('Erro relacionado a e-mail detectado');
      } else if (errorMessageLower.contains('password') ||
                errorMessageLower.contains('senha')) {
        errorMessage = 'A senha não atende aos requisitos mínimos.';
        _senhaError = 'Senha inválida';
        debugPrint('Erro de senha detectado');
      } else {
        errorMessage = 'Erro ao processar o cadastro. Tente novamente.';
        debugPrint('Mensagem de erro genérica: $errorMessageStr');
      }
      
      // Atualiza a interface para mostrar a mensagem de erro
      if (mounted) {
        setState(() {
          // Força a atualização da UI
        });
      }
      
      if (context.mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
      
      setState(() {
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  const Center(
                    child: Text(
                      'Crie sua conta',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Preencha os campos abaixo para criar sua conta',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campo de e-mail
                  const Text('E-mail',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Digite seu e-mail',
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: _emailError,
                      errorStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nome completo
                  const Text('Nome completo',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      hintText: 'Digite seu nome completo',
                      prefixIcon: const Icon(Icons.person_outline),
                      errorText: _nomeError,
                      errorStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Telefone
                  const Text('Telefone',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _telefoneController,
                    inputFormatters: [maskPhone],
                    decoration: InputDecoration(
                      hintText: '(00) 00000-0000',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      errorText: _telefoneError,
                      errorStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  
                  // CPF
                  const Text('CPF',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cpfController,
                    inputFormatters: [maskCpf],
                    decoration: InputDecoration(
                      hintText: '000.000.000-00',
                      prefixIcon: const Icon(Icons.credit_card_outlined),
                      errorText: _cpfError,
                      errorStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Senha
                  const Text('Senha',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _senhaController,
                    decoration: InputDecoration(
                      hintText: 'Crie uma senha forte',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      errorText: _senhaError,
                      errorStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: _obscurePassword,
                  ),
                  const SizedBox(height: 16),

                  // Confirmar senha
                  const Text('Confirmar senha',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmarSenhaController,
                    decoration: InputDecoration(
                      hintText: 'Digite a senha novamente',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      errorText: _confirmarSenhaError,
                      errorStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    onChanged: (_) {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Termos e condições
                  Row(
                    children: [
                      Checkbox(
                        value: _aceitouTermos,
                        onChanged: (value) {
                          setState(() {
                            _aceitouTermos = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _aceitouTermos = !_aceitouTermos;
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.grey[800]),
                              children: [
                                const TextSpan(text: 'Li e concordo com os '),
                                TextSpan(
                                  text: 'Termos de Uso',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: ' e '),
                                TextSpan(
                                  text: 'Política de Privacidade',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mensagem de erro
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Botão de cadastro
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_isFormValid) ? null : _register,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: _isFormValid && !_isLoading 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[400],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              'CRIAR CONTA',
                              style: TextStyle(
                                fontSize: 16,
                                color: _isFormValid ? Colors.white : Colors.grey[600],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Link para login
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.grey[800]),
                          children: [
                            const TextSpan(text: 'Já tem uma conta? '),
                            TextSpan(
                              text: 'Faça login',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

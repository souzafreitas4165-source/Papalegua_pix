import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:papaleguas_pix/services/api_service.dart';
import 'package:papaleguas_pix/services/app_state_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:papaleguas_pix/utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 11) text = text.substring(0, 11);
    String formatted = text;
    
    if (text.isNotEmpty) {
      formatted = '(${text.substring(0, text.length > 2 ? 2 : text.length)}';
      if (text.length > 2) {
        formatted += ') ${text.substring(2, text.length > 7 ? 7 : text.length)}';
        if (text.length > 7) {
          formatted += '-${text.substring(7)}';
        }
      }
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _maskCpf(String cpf) {
    final clean = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 11) return cpf;
    return '${clean.substring(0, 3)}.***.***-${clean.substring(9)}';
  }

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  String? _fotoPath;
  String? _fotoUrl;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _nomeError, _telefoneError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = ApiService().usuarioAtual;
    if (userId != null) {
      final dados = await ApiService().getUserProfile(userId);
      if (dados != null) {
        _nomeController.text = dados['nome'] ?? '';
        _telefoneController.text = dados['telefone'] ?? '';
        _fotoUrl = dados['foto'];
        _emailController.text = dados['email'] ?? '';
      }
    }
    // Carrega e mantém local (caso queira fallback offline)
    _emailController.text = prefs.getString('profile_email') ?? '';
    _fotoPath = prefs.getString('profile_foto');
    _isLoading = false;
    setState(() {});
  }

  Future<void> _saveProfile() async {
    setState(() {
      _nomeError = null;
      _telefoneError = null;
    });
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final telefone = _telefoneController.text.trim();
    bool hasError = false;
    if (nome.isEmpty) {
      _nomeError = 'O nome é obrigatório.';
      hasError = true;
    } else if (!isValidName(nome)) {
      _nomeError = 'Nome inválido (apenas letras e espaços, mínimo 3 letras).';
      hasError = true;
    }
    if (!isValidEmail(email)) {
      // Apenas valida o formato, mas não impede a atualização
      // já que o e-mail não pode ser alterado
    }
    if (!isValidPhoneBR(telefone)) {
      _telefoneError = 'Telefone inválido (use DDD, ex: 11999999999).';
      hasError = true;
    }
    setState(() {});
    if (hasError) return;
    try {
      // Atualiza localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_nome', nome);
      await prefs.setString('profile_email', email);
      await prefs.setString('profile_telefone', telefone);
      if (_fotoPath != null) await prefs.setString('profile_foto', _fotoPath!);
      // Atualiza no backend Supabase
      final userId = ApiService().usuarioAtual;
      if (userId != null) {
        await ApiService().updateUserProfile(
            userId: userId, nome: nome, telefone: telefone, foto: _fotoUrl);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil salvo com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar perfil: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }
  
  // Obtém o tema atual do aplicativo
  ThemeMode _getCurrentThemeMode(BuildContext context) {
    return context.read<AppStateManager>().themeMode;
  }

  // Exibe uma mensagem de erro em um SnackBar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Exibe uma mensagem de sucesso em um SnackBar
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Obtém uma mensagem de erro amigável
  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Ocorreu um erro inesperado. Tente novamente mais tarde.';
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (picked == null) return;
    final userId = ApiService().usuarioAtual;
    if (userId == null) {
      _showErrorSnackBar('Usuário não autenticado');
      return;
    }
    
    final file = File(picked.path);
    setState(() => _isLoading = true);
    
    try {
      final url = await ApiService().uploadProfilePhoto(file, userId);
      if (url != null) {
        await ApiService().updateProfilePhotoUrl(userId, url);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_foto_url', url);
        
        if (mounted) {
          setState(() {
            _fotoUrl = url;
          });
          _showSuccessSnackBar('Foto atualizada com sucesso!');
        }
      } else {
        _showErrorSnackBar('Não foi possível fazer upload da foto');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao enviar foto: ${_getErrorMessage(e)}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Método para alternar entre modo de visualização e edição
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  // Método para construir uma linha de informação não editável
  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : 'Não informado',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Método para construir uma linha de informação editável
  Widget _buildEditableInfoRow(
    BuildContext context,
    String label,
    String value,
    TextEditingController controller,
    String? errorText, {
    bool isRequired = false,
    bool isPhone = false,
  }) {
    if (!_isEditing) {
      return _buildInfoRow(
        label + (isRequired ? ' *' : ''),
        value.isNotEmpty ? value : 'Não informado',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 12),
          ),
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          inputFormatters: isPhone
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  _TelefoneInputFormatter(),
                ]
              : null,
          readOnly: label.toLowerCase().contains('e-mail'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cpf = ApiService().usuarioAtual ?? '--';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: _toggleEditMode,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 64,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: _fotoUrl != null
                            ? NetworkImage(_fotoUrl!)
                            : (_fotoPath != null
                                ? FileImage(File(_fotoPath!))
                                : null) as ImageProvider<Object>?,
                        child: (_fotoUrl == null && _fotoPath == null)
                            ? const Icon(Icons.person,
                                size: 64, color: Colors.white)
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt,
                                  color: Colors.white),
                              onPressed: _pickAndUploadPhoto,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Informações do perfil
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('CPF', _maskCpf(cpf)),
                        const Divider(height: 24),
                        _buildEditableInfoRow(
                          context,
                          'Nome',
                          _nomeController.text,
                          _nomeController,
                          _nomeError,
                          isRequired: true,
                        ),
                        const Divider(height: 24),
                        _buildInfoRow('E-mail', _emailController.text),
                        const Divider(height: 24),
                        _buildEditableInfoRow(
                          context,
                          'Telefone',
                          _telefoneController.text,
                          _telefoneController,
                          _telefoneError,
                          isPhone: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_isEditing) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        _saveProfile().then((_) {
                          if (_nomeError == null && _telefoneError == null) {
                            _toggleEditMode();
                          }
                        });
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar alterações'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _toggleEditMode,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: _toggleEditMode,
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar perfil'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Seção de preferências
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preferências',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.color_lens, size: 20),
                                SizedBox(width: 8),
                                Text('Tema Escuro'),
                              ],
                            ),
                            DropdownButton<ThemeMode>(
                              value: _getCurrentThemeMode(context),
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text('Sistema'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text('Claro'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text('Escuro'),
                                ),
                              ],
                              onChanged: (mode) {
                                if (mode != null) {
                                  final appState = context.read<AppStateManager>();
                                  appState.setThemeMode(mode);
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        ListTile(
                          leading: const Icon(Icons.lock),
                          title: const Text('Alterar senha'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Redirecionando para a tela de alteração de senha')),
                            );
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Sair da conta',
                              style: TextStyle(color: Colors.red)),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Sair da conta'),
                                content: const Text(
                                    'Tem certeza que deseja sair da sua conta?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .popUntil((route) => route.isFirst);
                                      ApiService().logout();
                                    },
                                    child: const Text('Sair',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}


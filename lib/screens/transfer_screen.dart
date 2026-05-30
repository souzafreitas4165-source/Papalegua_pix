import 'package:flutter/material.dart';
import 'package:papaleguas_pix/services/api_service.dart';
import 'package:papaleguas_pix/services/account_service.dart';
import 'package:flutter/services.dart';
import 'package:papaleguas_pix/screens/receipt_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:papaleguas_pix/widgets/secure_screen.dart';
import 'package:share_plus/share_plus.dart';

// Formatador de CPF
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) formatted += '.';
      if (i == 9) formatted += '-';
      formatted += digits[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Formatador de Celular (BR)
class CelularInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 0) formatted += '(';
      if (i == 2) formatted += ') ';
      if (i == 7) formatted += '-';
      formatted += digits[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final AccountService _accountService = AccountService();

  String _selectedPixType = 'cpf';
  double _saldo = 0.0;
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;
  // Removido _favoritos não utilizado
  Map<String, dynamic>? _recipientAccount;
  final _formKey = GlobalKey<FormState>();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchSaldoEHistorico();
    _fetchCotacoes();
    _loadFavoritos();
    
    // Temporário: Listar todos os usuários para depuração
    debugPrint('=== INICIANDO DEPURAÇÃO ===');
    _listAllUsers();
  }
  
  // Função auxiliar para listar usuários
  Future<void> _listAllUsers() async {
    try {
      debugPrint('Buscando lista de usuários...');
      final response = await _accountService.supabase
          .from('users')
          .select('user_id, email, nome')
          .order('email');
          
      debugPrint('=== LISTA DE USUÁRIOS CADASTRADOS ===');
      if (response.isEmpty) {
        debugPrint('Nenhum usuário encontrado no banco de dados');
      } else {
        debugPrint('Total de usuários: ${response.length}');
        for (var user in response) {
          debugPrint('--------------------------------');
          debugPrint('ID: ${user['id']}');
          debugPrint('Nome: ${user['nome']}');
          debugPrint('E-mail: ${user['email']}');
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar usuários: $e');
    }

    // Adiciona listener para buscar conta quando o campo de destinatário perder o foco
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _recipientController.text.isNotEmpty) {
        _searchRecipient();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoritos() async {
    // Método mantido vazio pois a funcionalidade de favoritos foi removida
    await Future.delayed(Duration.zero); // Evita warning de método vazio
  }

  // Método removido pois a validação é feita diretamente no validador do campo

  Future<void> _searchRecipient() async {
    final searchTerm = _recipientController.text.trim();
    if (searchTerm.isEmpty) {
      setState(() => _recipientAccount = null);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final account = await _accountService.searchAccount(searchTerm);
      setState(() {
        _recipientAccount = account;
        _errorMessage = account == null ? 'Conta não encontrada' : null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao buscar conta: $e';
        _recipientAccount = null;
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _transferir() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recipientAccount == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _errorMessage = 'Usuário não autenticado');
      return;
    }

    if (userId == _recipientAccount!['user_id']) {
      setState(() =>
          _errorMessage = 'Não é possível transferir para a própria conta');
      return;
    }

    final valor =
        double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) /
            100;

    setState(() => _isLoading = true);

    try {
      final result = await _accountService.transfer(
        fromUserId: userId,
        toUserId: _recipientAccount!['user_id'],
        amount: valor,
        description: 'Transferência via PIX',
      );

      if (result['success'] == true) {
        // Atualiza o saldo local
        await _fetchSaldoEHistorico();

        // Navega para o comprovante
        if (mounted) {
          final now = DateTime.now();
          final formattedDate =
              '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

          if (mounted) {
            // Usa o nome do destinatário ou um valor padrão seguro
            final destinatario = _recipientAccount?['nome']?.toString() ?? 
                               _recipientController.text;
                                
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReceiptScreen(
                  destinatario: destinatario,
                  valorEmReais: valor,
                  data: formattedDate,
                  moeda: 'BRL',
                  valorOriginal: valor,
                ),
              ),
            );
          }

          // Limpa o formulário
          _recipientController.clear();
          _amountController.clear();
          setState(() => _recipientAccount = null);
        }
      } else {
        setState(() => _errorMessage =
            result['error'] ?? 'Erro ao realizar transferência');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao realizar transferência: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchCotacoes() async {
    try {
      final apiService = ApiService();
      final cotacoes = await apiService.fetchCotacoes();
      debugPrint('Cotações carregadas: $cotacoes');
    } catch (e) {
      debugPrint('Erro ao buscar cotações: $e');
    }
  }

  Future<void> _fetchSaldoEHistorico() async {
    try {
      final apiService = ApiService();
      final saldo = await apiService.fetchSaldo();

      if (mounted) {
        setState(() {
          _saldo = saldo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar saldo: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transferência PIX'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Compartilhar',
              onPressed: () {
                SharePlus.instance.share(ShareParams(
                  text: '💸 Fiz uma transferência PIX pelo Papaleguas Pix!\nBanco digital completo.',
                ));
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo de valor em reais
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Valor em Reais',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: _amountController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _amountController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _RealInputFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o valor da transferência';
                }
                final valor =
                    double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ??
                        0.0;
                if (valor < 50) {
                  return 'O valor mínimo é R\$ 0,50';
                }
                if (valor / 100 > _saldo) {
                  return 'Saldo insuficiente';
                }
                return null;
              },
            ),

            const SizedBox(height: 24.0),

            // Seletor de tipo de chave PIX
            DropdownButtonFormField<String>(
              value: _selectedPixType,
              decoration: InputDecoration(
                labelText: 'Tipo de chave PIX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'cpf', child: Text('CPF')),
                DropdownMenuItem(value: 'email', child: Text('E-mail')),
                DropdownMenuItem(value: 'celular', child: Text('Celular')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPixType = value;
                    _recipientController.clear();
                    _recipientAccount = null;
                  });
                }
              },
            ),

            const SizedBox(height: 16.0),

            // Campo de destinatário
            TextFormField(
              controller: _recipientController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: _getRecipientFieldLabel(),
                hintText: _getRecipientHint(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _recipientController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _recipientController.clear();
                              setState(() => _recipientAccount = null);
                            },
                          )
                        : null,
              ),
              keyboardType: _getKeyboardType(),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _searchRecipient(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o destinatário';
                }
                if (_recipientAccount == null) {
                  return 'Conta não encontrada';
                }
                return null;
              },
            ),

            // Informações do destinatário
            if (_recipientAccount != null) ...[
              const SizedBox(height: 16.0),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recipientAccount!['nome'] ?? 'Nome não informado',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8.0),
                      if (_recipientAccount!['cpf'] != null)
                        _buildInfoRow(
                            'CPF', _formatCpf(_recipientAccount!['cpf'])),
                      if (_recipientAccount!['email'] != null)
                        _buildInfoRow('E-mail', _recipientAccount!['email']),
                      if (_recipientAccount!['telefone'] != null)
                        _buildInfoRow('Telefone',
                            _formatPhone(_recipientAccount!['telefone'])),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24.0),

            // Botão de transferir
            ElevatedButton(
              onPressed: _isLoading || _isSearching || _recipientAccount == null
                  ? null
                  : _transferir,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Transferir',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            // Saldo disponível
            const SizedBox(height: 16.0),
            Text(
              'Saldo disponível: R\$ ${_saldo.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color
                    ?.withAlpha((255 * 0.8).round()),
              ),
            ),

            // Mensagem de erro
            if (_errorMessage != null) ...[
              const SizedBox(height: 16.0),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _getRecipientFieldLabel() {
    switch (_selectedPixType) {
      case 'cpf':
        return 'CPF do destinatário';
      case 'email':
        return 'E-mail do destinatário';
      case 'celular':
        return 'Celular do destinatário';
      default:
        return 'Chave PIX';
    }
  }

  String _getRecipientHint() {
    switch (_selectedPixType) {
      case 'cpf':
        return '000.000.000-00';
      case 'email':
        return 'email@exemplo.com';
      case 'celular':
        return '(00) 00000-0000';
      default:
        return '';
    }
  }

  TextInputType _getKeyboardType() {
    switch (_selectedPixType) {
      case 'cpf':
      case 'celular':
        return TextInputType.phone;
      case 'email':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }

  String _formatCpf(String cpf) {
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }

  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return phone;
  }
}

class _RealInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final value = int.tryParse(cleanText) ?? 0;

    final formattedText = (value / 100).toStringAsFixed(2).replaceAll('.', ',');
    final newSelection = TextSelection.collapsed(offset: formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: newSelection,
    );
  }
}

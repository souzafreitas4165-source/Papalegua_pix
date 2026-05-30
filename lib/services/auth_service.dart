import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _error;
  User? _currentUser;

  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;

  AuthService() {
    // Inicializa com o usuário atual se existir
    _currentUser = _supabase.auth.currentUser;
    
    // Escuta mudanças no estado de autenticação
    _supabase.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      notifyListeners();
    });
  }

  // Registra um novo usuário
  Future<void> register({
    required String email,
    required String password,
    required String nome,
    required String telefone,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Iniciando registro para: $email');
      print('URL do Supabase: ${_supabase.rest.url}');
      print('Chave anônima: ${_supabase.rest.headers['apikey']}');

      // Verificar se o e-mail já está cadastrado
      print('Verificando se o e-mail já está cadastrado...');
      try {
        final existingEmail = await _supabase
            .from('users')
            .select('email')
            .eq('email', email)
            .maybeSingle();
            
        if (existingEmail != null) {
          throw 'Já existe um usuário cadastrado com este e-mail';
        }
      } on PostgrestException catch (e) {
        if (e.code != 'PGRST116') { // PGRST116 = nenhum resultado
          print('Erro ao verificar e-mail existente: $e');
          rethrow;
        }
      }

      // Registrar o usuário no Auth
      print('Criando novo usuário...');
      AuthResponse? authResponse;
      try {
        authResponse = await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'nome': nome,
            'telefone': telefone,
            'tipo_pessoa': 'fisica', // Mantido para compatibilidade
          },
        );
        print('Resposta do signUp: ${authResponse.user?.email}');
      } catch (signUpError) {
        print('Erro durante o signUp: $signUpError');
        print('Tipo de erro: ${signUpError.runtimeType}');
        if (signUpError is AuthException) {
          print('Código de erro: ${signUpError.statusCode}');
          print('Mensagem: ${signUpError.message}');
          // Melhora a mensagem de erro para o usuário
          if (signUpError.message.contains('already registered')) {
            throw 'Já existe um usuário cadastrado com este e-mail';
          }
        } else if (signUpError is Error) {
          print('Stack trace: ${signUpError.stackTrace}');
        }
        rethrow;
      }

      if (authResponse.user == null) {
        throw 'Falha ao criar usuário';
      }

      final userId = authResponse.user!.id;
      
      // O perfil do usuário já é criado pelo trigger on_auth_user_created
      // Cria o perfil do usuário no banco de dados
      await _createUserProfile(
        userId: userId,
        email: email,
        nome: nome,
        telefone: telefone,
      );
      
      print('Registro concluído com sucesso para o usuário $userId');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }



  // Cria o perfil do usuário
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String nome,
    required String telefone,
  }) async {
    try {
      await _supabase.from('users').upsert({
        'user_id': userId,
        'email': email,
        'nome': nome,
        'telefone': telefone,
        'tipo_pessoa': 'fisica', // Mantido para compatibilidade
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Se falhar, tenta novamente
      await Future.delayed(const Duration(seconds: 1));
      await _supabase.from('users').upsert({
        'user_id': userId,
        'email': email,
        'nome': nome,
        'telefone': telefone,
        'tipo_pessoa': 'fisica', // Mantido para compatibilidade
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    }
  }

  // Faz login
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Tentando fazer login com: $email');
      
      // Verifica se o e-mail está vazio
      if (email.isEmpty) {
        throw 'Por favor, informe o e-mail';
      }
      
      // Verifica se a senha está vazia
      if (password.isEmpty) {
        throw 'Por favor, informe a senha';
      }

      try {
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.user == null) {
          throw 'Falha ao fazer login. Tente novamente.';
        }

        _currentUser = response.user;
        _isLoading = false;
        notifyListeners();
        return true;
      } on AuthException catch (e) {
        print('Erro de autenticação: ${e.message}');
        
        // Melhora as mensagens de erro para o usuário
        if (e.message.contains('Invalid login credentials')) {
          throw 'E-mail ou senha incorretos';
        } else if (e.message.contains('Email not confirmed')) {
          throw 'Por favor, verifique seu e-mail para confirmar o cadastro';
        } else if (e.message.contains('User not found')) {
          throw 'Nenhuma conta encontrada com este e-mail';
        } else if (e.message.contains('Invalid email or password')) {
          throw 'E-mail ou senha incorretos';
        } else {
          throw 'Erro ao fazer login: ${e.message}';
        }
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Faz logout
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _supabase.auth.signOut();
      _currentUser = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Alias para compatibilidade com código existente
  Future<void> logout() => signOut();

  // Verifica se o usuário está autenticado
  Future<bool> checkAuth() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _currentUser = _supabase.auth.currentUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Limpa os erros
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

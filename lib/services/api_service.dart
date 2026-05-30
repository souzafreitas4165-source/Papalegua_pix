import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// Alias para facilitar o uso
void logDebug(String message) => debugPrint('ApiService: $message');

class ApiService {
  final SupabaseClient _supabase;

  ApiService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  // --- Cotação real via AwesomeAPI ---
  Future<Map<String, double>> fetchCotacoes() async {
    try {
      final response = await _supabase.functions.invoke('cotacoes', body: {});
      if (response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return {
          'dolar': double.parse(data['dolar'].toString()),
          'euro': double.parse(data['euro'].toString()),
        };
      } else {
        throw Exception('Não foi possível buscar as cotações no momento.');
      }
    } catch (e) {
      logDebug('Erro ao buscar cotações: $e');
      rethrow;
    }
  }

  // --- Saldo/histórico por usuário autenticado ---
  Future<double> fetchSaldo() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception(
            'Você precisa estar logado para acessar esta funcionalidade.');
      }

      final data = await _supabase
          .from('accounts')
          .select('balance')
          .eq('user_id', userId)
          .single();

      return (data['balance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      logDebug('Erro ao buscar saldo: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchHistorico() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception(
            'Você precisa estar logado para acessar esta funcionalidade.');
      }

      final data = await _supabase
          .from('transfers')
          .select()
          .eq('user_id', userId)
          .order('data', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      logDebug('Erro ao buscar histórico: $e');
      rethrow;
    }
  }

  Future<String?> uploadProfilePhoto(File file, String userId) async {
    try {
      final storage = _supabase.storage.from('profile-photos');
      final filePath =
          'user_$userId/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      await storage.upload(filePath, file);
      final url = storage.getPublicUrl(filePath);

      await updateUserProfile(userId: userId, foto: url);

      return url;
    } catch (e) {
      logDebug('Erro ao fazer upload da foto: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      logDebug('Erro ao buscar perfil do usuário: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(
      {required String userId,
      String? nome,
      String? telefone,
      String? foto}) async {
    try {
      final updateData = <String, dynamic>{};
      if (nome != null) updateData['nome'] = nome;
      if (telefone != null) updateData['telefone'] = telefone;
      if (foto != null) updateData['foto'] = foto;

      if (updateData.isNotEmpty) {
        updateData['updated_at'] = DateTime.now().toIso8601String();
        await _supabase.from('users').update(updateData).eq('user_id', userId);
      }
    } catch (e) {
      logDebug('Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  Future<void> updateProfilePhotoUrl(String userId, String url) async {
    await updateUserProfile(userId: userId, foto: url);
  }

  Future<void> registrarTransferencia(
    String destinatario,
    double valor, {
    String? moeda,
    double? valorOriginal,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final accountData = await _supabase
          .from('accounts')
          .select('balance')
          .eq('user_id', userId)
          .single();

      final currentBalance =
          (accountData['balance'] as num?)?.toDouble() ?? 0.0;

      if (currentBalance < valor) {
        throw Exception('Saldo insuficiente para realizar esta operação.');
      }

      await _supabase.rpc('transfer_between_accounts', params: {
        'from_user_id': userId,
        'to_user_id': destinatario,
        'amount': valor,
        'description': 'Transferência entre contas',
      });
    } catch (e) {
      logDebug('Erro ao registrar transferência: $e');
      rethrow;
    }
  }

  Future<Map<String, double>> getExchangeRates() async {
    try {
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/BRL'),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Falha ao carregar as cotações. Código: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['result'] != 'success') {
        throw Exception('Falha na resposta da API de cotações');
      }

      final rates = data['rates'] as Map<String, dynamic>;
      return {
        'USD': 1 / (rates['USD'] ?? 1.0),
        'EUR': 1 / (rates['EUR'] ?? 1.0),
      };
    } catch (e) {
      logDebug('Erro ao buscar taxas de câmbio: $e');
      rethrow;
    }
  }

  Future<bool> checkIfDocumentExists(String document,
      {bool isCpf = true}) async {
    try {
      if (document.isEmpty) return false;
      final cleanDoc = document.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanDoc.isEmpty) return false;

      final response = await _supabase
          .from('users')
          .select('user_id, email')
          .eq('cpf', cleanDoc)
          .maybeSingle();

      return response != null && response['user_id'] != null;
    } on PostgrestException catch (e) {
      if (e.message.contains('No data found') || e.message.contains('0 rows')) {
        return false;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> findUserByDocument(String document) async {
    try {
      if (document.isEmpty) return null;
      final cleanDoc = document.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanDoc.isEmpty) return null;

      final response = await _supabase
          .from('users')
          .select('*')
          .eq('cpf', cleanDoc)
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      if (e.message.contains('No data found') || e.message.contains('0 rows')) {
        return null;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  String? get usuarioAtual => _supabase.auth.currentUser?.id;
  bool get isLoggedIn => _supabase.auth.currentUser != null;

  Future<bool> login(String identificador, String senha) async {
    try {
      String email;
      if (identificador.contains('@')) {
        email = identificador;
      } else {
        email =
            '${identificador.replaceAll(RegExp(r'[^0-9]'), '')}@urubupix.com';
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: senha,
      );

      return response.user != null;
    } on AuthException catch (e) {
      logDebug('Erro de autenticação: ${e.message}');
      rethrow;
    } catch (e) {
      logDebug('Erro ao fazer login: $e');
      rethrow;
    }
  }

  Future<bool> register(
    String email,
    String senha, {
    required String nome,
    required String telefone,
    required String cpf,
  }) async {
    try {
      final emailFormatado = email.trim().toLowerCase();

      try {
        final emailExists = await _supabase
            .from('users')
            .select('email')
            .eq('email', emailFormatado)
            .maybeSingle();

        if (emailExists != null) {
          throw AuthException(
              'Já existe um usuário cadastrado com este e-mail');
        }
      } catch (e) {
        if (!e.toString().contains('No data found')) rethrow;
      }

      final cpfExists = await checkIfDocumentExists(cpf);
      if (cpfExists) {
        throw AuthException('Já existe um usuário cadastrado com este CPF');
      }

      final authResponse = await _supabase.auth.signUp(
        email: emailFormatado,
        password: senha,
        data: {
          'nome': nome,
          'telefone': telefone,
          'cpf': cpf,
          'email_verified': true,
        },
      );

      if (authResponse.user == null) {
        throw AuthException('Erro ao criar o usuário. Tente novamente.');
      }

      return true;
    } on AuthException catch (e) {
      logDebug('Erro de autenticação: ${e.message}');
      rethrow;
    } catch (e) {
      throw AuthException(
          'Ocorreu um erro inesperado. Por favor, tente novamente.');
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  static Future<Map<String, List<MapEntry<DateTime, double>>>>
      getExchangeRateHistory() async {
    logDebug('Buscando histórico de cotações...');
    try {
      final now = DateTime.now();
      final Map<String, List<MapEntry<DateTime, double>>> history = {
        'USD': [],
        'EUR': [],
      };

      final response =
          await Supabase.instance.client.functions.invoke('cotacoes', body: {});

      if (response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final dolarRate =
            double.tryParse(data['dolar']?.toString() ?? '0') ?? 0;
        final euroRate = double.tryParse(data['euro']?.toString() ?? '0') ?? 0;

        for (int i = 0; i < 7; i++) {
          final date = now.subtract(Duration(days: i));
          final variation = 1.0 + (0.02 * (i / 7));

          if (dolarRate > 0)
            history['USD']!.add(MapEntry(date, dolarRate * variation));
          if (euroRate > 0)
            history['EUR']!.add(MapEntry(date, euroRate * variation));
        }

        for (var entry in history.entries) {
          entry.value.sort((a, b) => a.key.compareTo(b.key));
        }

        return history;
      } else {
        throw Exception('Não foi possível buscar o histórico de cotações');
      }
    } catch (e, stackTrace) {
      throw ApiException(
        message:
            'Não foi possível buscar o histórico de cotações. Por favor, tente novamente mais tarde.',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  ApiException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

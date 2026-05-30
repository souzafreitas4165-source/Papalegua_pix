import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:papaleguas_pix/models/paginated_response.dart';
import 'package:papaleguas_pix/services/cache_service.dart';
import 'package:papaleguas_pix/services/api_service.dart';

class AccountService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Getter público para o cliente Supabase
  SupabaseClient get supabase => _supabase;

  // Verifica e cria uma conta se não existir
  Future<void> ensureAccountExists(String userId) async {
    try {
      debugPrint('Verificando se a conta existe para o usuário: $userId');
      
      // Primeiro, tenta buscar a conta
      try {
        final account = await _supabase
            .from('accounts')
            .select('*')
            .eq('user_id', userId)
            .maybeSingle();
            
        if (account != null) {
          debugPrint('✅ Conta encontrada para o usuário $userId');
          return;
        }
      } catch (e) {
        // Se der erro 406 (Not Found), a conta não existe
        if (e is PostgrestException && e.code != 'PGRST116') {
          rethrow;
        }
      }
      
      // Se chegou aqui, a conta não existe ou não pôde ser acessada
      debugPrint('Conta não encontrada para o usuário $userId. Verificando se o usuário existe...');
      
      try {
        // Verifica se o usuário existe na tabela users
        await _supabase
            .from('users')
            .select()
            .eq('user_id', userId)
            .single();
            
        debugPrint('✅ Usuário encontrado na tabela users, a conta será criada pelo trigger');
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST116') {
          debugPrint('⚠️ Usuário não encontrado na tabela users');
          throw Exception('Usuário não encontrado no sistema');
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar/criar conta: $e');
      // Não relançamos o erro para não interromper o fluxo principal
    }
  }

  // Busca os dados de uma conta pelo ID do usuário
  Future<Map<String, dynamic>?> getAccountByUserId(String userId) async {
    try {
      debugPrint('\n=== INÍCIO DA BUSCA DE CONTA ===');
      debugPrint('Buscando conta para o usuário: $userId');
      
      // Primeiro busca os dados do usuário
      debugPrint('Buscando dados do usuário...');
      final userResponse = await _supabase
          .from('users')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('❌ Usuário não encontrado na tabela users: $userId');
        
        // Verifica se há algum usuário na tabela
        final allUsers = await _supabase
            .from('users')
            .select('user_id, email')
            .limit(5);
            
        debugPrint('\n=== AMOSTRA DE USUÁRIOS NA TABELA ===');
        if (allUsers.isEmpty) {
          debugPrint('Nenhum usuário encontrado na tabela users');
        } else {
          debugPrint('Total de usuários: ${allUsers.length}');
          for (var user in allUsers) {
            debugPrint('- ID: ${user['user_id']}');
            debugPrint('  Email: ${user['email']}');
          }
        }
        
        return null;
      }
      
      debugPrint('✅ Dados do usuário encontrados:');
      debugPrint('- Nome: ${userResponse['nome']}');
      debugPrint('- Email: ${userResponse['email']}');

      // Usa a função RPC para buscar a conta (que já sabemos que funciona)
      debugPrint('Buscando dados da conta via RPC...');
      final directCheck = await _supabase
          .rpc('get_account_balance', params: {'p_user_id': userId});
      
      debugPrint('Resultado da consulta RPC: $directCheck');
      
      if (directCheck == null || directCheck['exists'] != true) {
        debugPrint('❌ Conta não encontrada via RPC para o usuário: $userId');
        return null;
      }
      
      final accountData = directCheck['account'] as Map<String, dynamic>?;
      
      if (accountData == null) {
        debugPrint('❌ Dados da conta inválidos na resposta RPC');
        return null;
      }
      
      debugPrint('✅ Dados da conta encontrados via RPC:');
      debugPrint('- Saldo: ${accountData['balance']}');
      debugPrint('- User ID: ${accountData['user_id']}');

      // Combina os dados do usuário e da conta
      final result = {
        'user_id': userId,
        'balance': accountData['balance']?.toDouble() ?? 0.0,
        'nome': userResponse['nome'],
        'cpf': userResponse['cpf'],
        'email': userResponse['email'],
        'telefone': userResponse['telefone'],
      };
      
      debugPrint('✅ Dados combinados da conta:');
      result.forEach((key, value) => debugPrint('- $key: $value'));
      
      return result;
    } catch (e) {
      debugPrint('Erro ao buscar conta: $e');
      return null;
    }
  }

  // Busca uma conta por CPF, e-mail ou telefone
  Future<Map<String, dynamic>?> searchAccount(String searchTerm) async {
    try {
      debugPrint('\n=== INÍCIO DA BUSCA DE CONTA ===');
      debugPrint('Termo de busca original: "$searchTerm"');
      
      final searchEmail = searchTerm.trim().toLowerCase();
      debugPrint('Buscando por e-mail: "$searchEmail"');
      
      // Primeiro, busca o usuário
      debugPrint('Buscando usuário...');
      final userResponse = await _supabase
          .from('users')
          .select('*')
          .eq('email', searchEmail)
          .maybeSingle();
          
      debugPrint('Resposta do usuário:');
      debugPrint(userResponse?.toString() ?? 'Usuário não encontrado');
      
      if (userResponse == null) {
        debugPrint('❌ Nenhum usuário encontrado com o e-mail: $searchEmail');
        
        // Busca todos os e-mails para depuração
        debugPrint('\n=== LISTA DE TODOS OS USUÁRIOS CADASTRADOS ===');
        final allUsers = await _supabase
            .from('users')
            .select('user_id, email')
            .order('email');
            
        if (allUsers.isEmpty) {
          debugPrint('Nenhum usuário encontrado no banco de dados');
        } else {
          debugPrint('Total de usuários: ${allUsers.length}');
          for (var user in allUsers) {
            final email = user['email']?.toString() ?? 'null';
            debugPrint('- ID: ${user['user_id']}');
            debugPrint('  E-mail: "$email"');
          }
        }
        
        return null;
      }
      
      final userId = userResponse['user_id'];
      debugPrint('✅ Dados do usuário encontrados:');
      debugPrint('- ID: $userId');
      debugPrint('- Nome: ${userResponse['nome']}');
      debugPrint('- E-mail: ${userResponse['email']}');
      debugPrint('- CPF: ${userResponse['cpf']}');
      
      // Busca o saldo da conta separadamente
      debugPrint('Buscando saldo da conta...');
      final accountResponse = await _supabase
          .from('accounts')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();
          
      final balance = accountResponse != null 
          ? (accountResponse['balance'] ?? 0.0).toDouble()
          : 0.0;
          
      debugPrint('Saldo da conta: $balance');
      
      return {
        'user_id': userId,
        'nome': userResponse['nome'],
        'cpf': userResponse['cpf'],
        'email': userResponse['email'],
        'telefone': userResponse['telefone'],
        'balance': balance,
      };
    } catch (e) {
      debugPrint('Erro ao buscar conta: $e');
      return null;
    }
  }

  // Realiza uma transferência entre contas
  Future<Map<String, dynamic>> transfer({
    required String fromUserId,
    required String toUserId,
    required double amount,
    String? description,
  }) async {
    // Garante que ambas as contas existam
    await ensureAccountExists(fromUserId);
    await ensureAccountExists(toUserId);
    try {
      debugPrint('\n=== INÍCIO DA TRANSFERÊNCIA ===');
      debugPrint('De: $fromUserId');
      debugPrint('Para: $toUserId');
      debugPrint('Valor: $amount');

      // Verifica se o valor é válido
      if (amount <= 0) {
        debugPrint('Valor inválido: $amount');
        return {'success': false, 'error': 'O valor da transferência deve ser maior que zero'};
      }

      // Verifica se as contas existem
      debugPrint('Verificando conta de origem...');
      final fromAccount = await getAccountByUserId(fromUserId);
      if (fromAccount == null) {
        debugPrint('❌ Conta de origem não encontrada: $fromUserId');
        return {'success': false, 'error': 'Conta de origem não encontrada'};
      }
      debugPrint('✅ Conta de origem encontrada: ${fromAccount['email']}');

      debugPrint('Verificando conta de destino...');
      final toAccount = await getAccountByUserId(toUserId);
      if (toAccount == null) {
        debugPrint('❌ Conta de destino não encontrada: $toUserId');
        return {'success': false, 'error': 'Conta de destino não encontrada'};
      }
      debugPrint('✅ Conta de destino encontrada: ${toAccount['email']}');

      // Verifica se há saldo suficiente
      final saldoAtual = (fromAccount['balance'] ?? 0.0).toDouble();
      debugPrint('Saldo atual: R\$ $saldoAtual');
      
      if (saldoAtual < amount) {
        final mensagemErro = 'Saldo insuficiente. Saldo disponível: R\$ $saldoAtual';
        debugPrint('❌ $mensagemErro');
        return {'success': false, 'error': mensagemErro};
      }

      // Inicia uma transação
      try {
        debugPrint('Iniciando transferência no banco de dados...');
        final response = await _supabase.rpc('transfer_money', params: {
          'p_from_user_id': fromUserId,
          'p_to_user_id': toUserId,
          'p_amount': amount.toString(),
          'p_description': description ?? 'Transferência entre contas',
        }).timeout(const Duration(seconds: 10));

        debugPrint('✅ Resposta da transferência: $response');
        
        // Converte a resposta para um Map
        final responseData = response as Map<String, dynamic>;
        
        if (responseData['success'] != true) {
          final error = responseData['error']?.toString() ?? 'Erro desconhecido';
          debugPrint('❌ Erro na transferência: $error');
          return {'success': false, 'error': error};
        }
        
        debugPrint('✅ Transferência realizada com sucesso!');
        debugPrint('ID da transação: ${responseData['transaction_id']}');
        debugPrint('Novo saldo: R\$${responseData['new_balance']}');
        
        // Atualiza o cache local com o novo saldo retornado
        final novoSaldo = (responseData['new_balance'] ?? 0.0).toDouble();
        await updateCachedBalance(fromUserId, novoSaldo);
        
        return {
          'success': true, 
          'data': {
            'from_user_id': fromUserId,
            'to_user_id': toUserId,
            'amount': amount,
            'new_balance': novoSaldo,
            'timestamp': DateTime.now().toIso8601String(),
          }
        };
      } catch (e) {
        debugPrint('❌ Erro ao realizar transferência: $e');
        return {
          'success': false, 
          'error': 'Erro ao processar a transferência. Tente novamente mais tarde.'
        };
      }
    } catch (e) {
      debugPrint('Erro na transferência: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Busca histórico de transações com paginação e cache
  Future<PaginatedResponse<Map<String, dynamic>>> getTransactionHistory({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // Tenta obter do cache primeiro
      final cacheKey = 'transactions_${userId}_$page';
      final cached = await CacheService.getFromCache(cacheKey);

      // Verifica se o cache está válido (não mais que 5 minutos)
      if (cached != null) {
        final lastUpdate = await CacheService.getLastUpdateTime(cacheKey);
        final now = DateTime.now();
        if (lastUpdate != null &&
            now.difference(lastUpdate) <= const Duration(minutes: 5)) {
          return PaginatedResponse<Map<String, dynamic>>.fromJson(
            cached,
            (item) => Map<String, dynamic>.from(item),
          );
        }
      }

      // Se não estiver em cache ou estiver expirado, busca no servidor
      final response = await _supabase
          .from('transactions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      // Primeiro busca o total de itens
      final countResponse = await _supabase
          .from('transactions')
          .select('id')
          .eq('user_id', userId);

      final totalItems = countResponse.length;
      final totalPages = (totalItems / limit).ceil();
      final hasNext = page < totalPages;

      final result = {
        'items': response,
        'current_page': page,
        'total_pages': totalPages,
        'total_items': totalItems,
        'has_next': hasNext,
        'last_update': DateTime.now().toIso8601String(),
      };

      // Salva no cache com compressão
      await CacheService.saveToCache(
        cacheKey,
        result,
        duration: const Duration(minutes: 5),
        compress: true,
      );

      // Pré-carrega a próxima página se houver
      if (hasNext) {
        _prefetchNextPage(userId, page + 1, limit);
      }

      return PaginatedResponse<Map<String, dynamic>>.fromJson(
        result,
        (item) => Map<String, dynamic>.from(item),
      );
    } catch (e) {
      debugPrint('Erro ao buscar histórico: $e');
      throw ApiException(
        message:
            'Não foi possível carregar o histórico de transações. Por favor, tente novamente mais tarde.',
        originalError: e,
      );
    }
  }

  Future<void> _prefetchNextPage(String userId, int page, int limit) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final cacheKey = 'transactions_${userId}_$page';
      await CacheService.saveToCache(
        cacheKey,
        {
          'items': response,
          'current_page': page,
          'last_update': DateTime.now().toIso8601String(),
        },
        duration: const Duration(minutes: 5),
        compress: true,
      );
    } catch (e) {
      // Ignora erros no prefetch
      debugPrint('Erro no prefetch da página $page: $e');
    }
  }

  // Busca saldo com cache
  Future<double> getCachedBalance(String userId) async {
    try {
      final cacheKey = 'balance_$userId';
      final cachedBalance = await CacheService.getFromCache(cacheKey);

      if (cachedBalance != null) {
        return double.parse(cachedBalance.toString());
      }

      final account = await getAccountByUserId(userId);
      final balance = (account?['balance'] ?? 0.0).toDouble();

      // Salva no cache por 1 minuto
      await CacheService.saveToCache(
        cacheKey,
        balance,
        duration: const Duration(minutes: 1),
      );

      return balance;
    } catch (e) {
      debugPrint('Erro ao buscar saldo em cache: $e');
      rethrow;
    }
  }

  // Atualiza o cache do saldo
  Future<void> updateCachedBalance(String userId, double newBalance) async {
    try {
      final cacheKey = 'balance_$userId';
      await CacheService.saveToCache(
        cacheKey,
        newBalance,
        duration: const Duration(minutes: 1),
      );
    } catch (e) {
      debugPrint('Erro ao atualizar cache do saldo: $e');
    }
  }

  
  // Função temporária para depuração - listar todos os usuários
  Future<void> debugListAllUsers() async {
    try {
      debugPrint('=== LISTANDO TODOS OS USUÁRIOS ===');
      final response = await _supabase
          .from('users')
          .select('id, email, nome, cpf')
          .order('email');
          
      if (response.isEmpty) {
        debugPrint('Nenhum usuário encontrado no banco de dados');
      } else {
        debugPrint('Total de usuários: ${response.length}');
        for (var user in response) {
          debugPrint('--------------------------------');
          debugPrint('ID: ${user['id']}');
          debugPrint('Nome: ${user['nome']}');
          debugPrint('E-mail: ${user['email']}');
          debugPrint('CPF: ${user['cpf']}');
        }
      }
    } catch (e) {
      debugPrint('Erro ao listar usuários: $e');
    }
  }
}

// Extensão para formatar dados sensíveis
extension SensitiveDataExtension on String {
  String obscureSensitiveData() {
    if (length <= 4) return this;
    return '••••${substring(length - 4)}';
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivity = Connectivity();
  StreamController<bool> connectionChangeController =
      StreamController.broadcast();
  bool _hasConnection = true;
  Timer? _syncTimer;
  static const Duration _syncInterval = Duration(minutes: 5);

  // Chaves para cache offline
  static const String _offlineDataKey = 'offline_data';
  static const String _pendingOperationsKey = 'pending_operations';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Endpoint base para sincronização (substitua pelo seu endpoint real)
  static const String _syncEndpoint = 'https://api.urubupix.com/sync';

  // Inicializa o serviço
  Future<void> initialize() async {
    _connectivity.onConnectivityChanged.listen(_connectionChange);
    await checkConnection();
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (timer) async {
      if (_hasConnection) {
        await _syncOfflineData();
      }
    });
  }

  // Monitora mudanças na conexão
  void _connectionChange(ConnectivityResult result) {
    _checkStatus(result);
  }

  // Verifica o status da conexão
  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return _checkStatus(result);
  }

  bool _checkStatus(ConnectivityResult result) {
    bool previousConnection = _hasConnection;
    _hasConnection = result != ConnectivityResult.none;

    if (previousConnection != _hasConnection) {
      connectionChangeController.add(_hasConnection);

      if (_hasConnection) {
        _syncOfflineData();
      }
    }

    return _hasConnection;
  }

  // Salva dados para uso offline
  Future<void> saveOfflineData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineData = await _getOfflineData();

      offlineData[key] = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_offlineDataKey, jsonEncode(offlineData));
    } catch (e) {
      debugPrint('Erro ao salvar dados offline: $e');
    }
  }

  // Recupera dados offline
  Future<dynamic> getOfflineData(String key) async {
    try {
      final offlineData = await _getOfflineData();
      return offlineData[key]?['data'];
    } catch (e) {
      debugPrint('Erro ao recuperar dados offline: $e');
      return null;
    }
  }

  // Registra operação pendente
  Future<void> addPendingOperation({
    required String type,
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOps = await _getPendingOperations();

      pendingOps.add({
        'type': type,
        'endpoint': endpoint,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await prefs.setString(_pendingOperationsKey, jsonEncode(pendingOps));
    } catch (e) {
      debugPrint('Erro ao adicionar operação pendente: $e');
    }
  }

  // Sincroniza dados offline quando a conexão é restaurada
  Future<void> _syncOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Obtém operações pendentes
      final pendingOps = await _getPendingOperations();
      if (pendingOps.isEmpty) return;

      debugPrint('Sincronizando ${pendingOps.length} operações pendentes...');

      // Agrupa operações por tipo
      final groupedOps = <String, List<Map<String, dynamic>>>{};
      for (final op in pendingOps) {
        final type = op['type'] as String;
        groupedOps[type] = [...(groupedOps[type] ?? []), op];
      }

      // Processa cada grupo de operações
      for (final entry in groupedOps.entries) {
        final type = entry.key;
        final operations = entry.value;

        try {
          final response = await http.post(
            Uri.parse('$_syncEndpoint/$type'),
            headers: {
              'Content-Type': 'application/json',
              'Last-Sync': lastSync.toString(),
            },
            body: jsonEncode({
              'operations': operations,
              'deviceInfo': await _getDeviceInfo(),
              'timestamp': now,
            }),
          );

          if (response.statusCode == 200) {
            // Processa a resposta do servidor
            final serverData = jsonDecode(response.body);
            await _processServerResponse(serverData);

            // Remove operações sincronizadas
            final successfulOps =
                serverData['successful_operations'] as List<String>;
            await _removeSyncedOperations(successfulOps);
          } else {
            throw Exception('Erro na sincronização: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Erro ao sincronizar operações do tipo $type: $e');
          // Mantém as operações para tentar novamente depois
          continue;
        }
      }

      // Atualiza timestamp da última sincronização
      await prefs.setInt(_lastSyncKey, now);
    } catch (e) {
      debugPrint('Erro ao sincronizar dados offline: $e');
    }
  }

  // Processa a resposta do servidor após sincronização
  Future<void> _processServerResponse(Map<String, dynamic> serverData) async {
    try {
      // Atualiza dados locais com dados do servidor
      if (serverData.containsKey('updated_data')) {
        final updatedData = serverData['updated_data'] as Map<String, dynamic>;
        await _updateLocalData(updatedData);
      }

      // Processa conflitos se houver
      if (serverData.containsKey('conflicts')) {
        final conflicts = serverData['conflicts'] as List<Map<String, dynamic>>;
        await _handleSyncConflicts(conflicts);
      }
    } catch (e) {
      debugPrint('Erro ao processar resposta do servidor: $e');
    }
  }

  // Atualiza dados locais com dados do servidor
  Future<void> _updateLocalData(Map<String, dynamic> updatedData) async {
    final prefs = await SharedPreferences.getInstance();
    final currentData = await _getOfflineData();

    // Mescla dados atualizados com dados locais
    for (final entry in updatedData.entries) {
      currentData[entry.key] = {
        'data': entry.value,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    await prefs.setString(_offlineDataKey, jsonEncode(currentData));
  }

  // Lida com conflitos de sincronização
  Future<void> _handleSyncConflicts(
      List<Map<String, dynamic>> conflicts) async {
    for (final conflict in conflicts) {
      try {
        final String operationId = conflict['operation_id'];
        final dynamic serverData = conflict['server_data'];
        final dynamic localData = conflict['local_data'];
        final String resolution = await _resolveConflict(serverData, localData);

        // Aplica a resolução do conflito
        if (resolution == 'server') {
          await _updateLocalData({operationId: serverData});
        } else if (resolution == 'local') {
          await addPendingOperation(
            type: 'force_update',
            endpoint: operationId,
            data: {'data': localData},
          );
        }
      } catch (e) {
        debugPrint('Erro ao resolver conflito: $e');
      }
    }
  }

  // Resolve conflitos de sincronização
  Future<String> _resolveConflict(dynamic serverData, dynamic localData) async {
    // Implementa sua lógica de resolução de conflitos aqui
    // Por padrão, mantém os dados do servidor
    return 'server';
  }

  // Remove operações já sincronizadas
  Future<void> _removeSyncedOperations(List<String> operationIds) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingOps = await _getPendingOperations();

    final remainingOps = pendingOps.where((op) {
      final opId = op['id'] as String?;
      return opId == null || !operationIds.contains(opId);
    }).toList();

    await prefs.setString(_pendingOperationsKey, jsonEncode(remainingOps));
  }

  // Obtém informações do dispositivo para sincronização
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      return {
        'platform': defaultTargetPlatform.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': 'Não foi possível obter informações do dispositivo'};
    }
  }

  // Recupera dados offline armazenados
  Future<Map<String, dynamic>> _getOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_offlineDataKey);
      if (data == null) return {};

      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      debugPrint('Erro ao recuperar dados offline: $e');
      return {};
    }
  }

  // Recupera operações pendentes
  Future<List<Map<String, dynamic>>> _getPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ops = prefs.getString(_pendingOperationsKey);
      if (ops == null) return [];

      final List<dynamic> decoded = jsonDecode(ops);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      debugPrint('Erro ao recuperar operações pendentes: $e');
      return [];
    }
  }

  // Limpa dados offline antigos
  Future<void> clearOldOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineData = await _getOfflineData();

      final now = DateTime.now();
      final filteredData =
          Map<String, dynamic>.fromEntries(offlineData.entries.where((entry) {
        final timestamp = DateTime.parse(entry.value['timestamp']);
        return now.difference(timestamp).inDays <= 7;
      }));

      await prefs.setString(_offlineDataKey, jsonEncode(filteredData));
    } catch (e) {
      debugPrint('Erro ao limpar dados offline antigos: $e');
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    connectionChangeController.close();
  }
}

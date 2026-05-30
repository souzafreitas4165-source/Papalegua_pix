import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static const String _eventsKey = 'analytics_events';
  static const String _errorsKey = 'analytics_errors';
  static const int _maxStoredEvents = 1000;
  static const int _maxStoredErrors = 100;

  // URLs dos servidores (substitua pelos endpoints reais)
  static const String _analyticsEndpoint =
      'https://analytics.urubupix.com/events';
  static const String _monitoringEndpoint =
      'https://monitoring.urubupix.com/errors';

  // Registra um evento
  Future<void> logEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
    bool isCritical = false,
  }) async {
    try {
      final event = {
        'name': eventName,
        'parameters': parameters,
        'timestamp': DateTime.now().toIso8601String(),
        'isCritical': isCritical,
      };

      final prefs = await SharedPreferences.getInstance();
      final events = await _getStoredEvents();

      events.add(event);
      if (events.length > _maxStoredEvents) {
        events.removeAt(0);
      }

      await prefs.setString(_eventsKey, jsonEncode(events));

      // Se for crítico, envia imediatamente
      if (isCritical) {
        await _sendEvents([event]);
      }
    } catch (e) {
      debugPrint('Erro ao registrar evento: $e');
    }
  }

  // Registra um erro
  Future<void> logError(
    dynamic error,
    StackTrace stackTrace, {
    String? context,
    bool isCritical = true,
  }) async {
    try {
      final errorLog = {
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
        'isCritical': isCritical,
        'deviceInfo': await _getDeviceInfo(),
        'appInfo': await _getAppInfo(),
      };

      final prefs = await SharedPreferences.getInstance();
      final errors = await _getStoredErrors();

      errors.add(errorLog);
      if (errors.length > _maxStoredErrors) {
        errors.removeAt(0);
      }

      await prefs.setString(_errorsKey, jsonEncode(errors));

      // Se for crítico, envia imediatamente
      if (isCritical) {
        await _sendErrors([errorLog]);
      }
    } catch (e) {
      debugPrint('Erro ao registrar erro: $e');
    }
  }

  // Recupera eventos armazenados
  Future<List<Map<String, dynamic>>> _getStoredEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_eventsKey);
      if (eventsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(eventsJson);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      debugPrint('Erro ao recuperar eventos: $e');
      return [];
    }
  }

  // Recupera erros armazenados
  Future<List<Map<String, dynamic>>> _getStoredErrors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorsJson = prefs.getString(_errorsKey);
      if (errorsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(errorsJson);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      debugPrint('Erro ao recuperar erros: $e');
      return [];
    }
  }

  // Envia eventos para o servidor
  Future<void> _sendEvents(List<Map<String, dynamic>> events) async {
    try {
      final response = await http.post(
        Uri.parse(_analyticsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
        body: jsonEncode({
          'events': events,
          'deviceInfo': await _getDeviceInfo(),
          'appInfo': await _getAppInfo(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao enviar eventos: ${response.statusCode}');
      }

      debugPrint('Eventos enviados com sucesso: ${events.length}');
    } catch (e) {
      debugPrint('Erro ao enviar eventos: $e');
      // Armazena para tentar novamente mais tarde
      await _storeForRetry('events', events);
    }
  }

  // Envia erros para o servidor
  Future<void> _sendErrors(List<Map<String, dynamic>> errors) async {
    try {
      final response = await http.post(
        Uri.parse(_monitoringEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
        body: jsonEncode({
          'errors': errors,
          'deviceInfo': await _getDeviceInfo(),
          'appInfo': await _getAppInfo(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao enviar erros: ${response.statusCode}');
      }

      debugPrint('Erros enviados com sucesso: ${errors.length}');
    } catch (e) {
      debugPrint('Erro ao enviar erros: $e');
      // Armazena para tentar novamente mais tarde
      await _storeForRetry('errors', errors);
    }
  }

  // Obtém informações do dispositivo
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      Map<String, dynamic> deviceData = {};

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceData = {
          'platform': 'android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'androidVersion': androidInfo.version.release,
          'sdkVersion': androidInfo.version.sdkInt,
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceData = {
          'platform': 'ios',
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
          'utsname': iosInfo.utsname.sysname,
        };
      } else {
        deviceData = {
          'platform': defaultTargetPlatform.toString(),
          'isPhysicalDevice': true,
        };
      }

      return deviceData;
    } catch (e) {
      return {'error': 'Não foi possível obter informações do dispositivo: $e'};
    }
  }

  // Obtém informações do app
  Future<Map<String, dynamic>> _getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'appName': packageInfo.appName,
        'packageName': packageInfo.packageName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      };
    } catch (e) {
      return {'error': 'Não foi possível obter informações do app'};
    }
  }

  // Obtém a chave de API
  Future<String> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('analytics_api_key') ?? '';
  }

  // Armazena dados para retry posterior
  Future<void> _storeForRetry(
      String type, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'retry_${type}_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(key, jsonEncode(data));
  }

  // Tenta reenviar dados armazenados
  Future<void> retryFailedUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('retry_'));

    for (final key in keys) {
      try {
        final data = jsonDecode(prefs.getString(key) ?? '[]');
        if (key.contains('events')) {
          await _sendEvents(List<Map<String, dynamic>>.from(data));
        } else if (key.contains('errors')) {
          await _sendErrors(List<Map<String, dynamic>>.from(data));
        }
        await prefs.remove(key);
      } catch (e) {
        debugPrint('Erro ao reenviar dados: $e');
      }
    }
  }

  // Limpa eventos antigos
  Future<void> clearOldEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final events = await _getStoredEvents();

      final now = DateTime.now();
      final filteredEvents = events.where((event) {
        final eventDate = DateTime.parse(event['timestamp']);
        return now.difference(eventDate).inDays <= 7;
      }).toList();

      await prefs.setString(_eventsKey, jsonEncode(filteredEvents));
    } catch (e) {
      debugPrint('Erro ao limpar eventos antigos: $e');
    }
  }

  // Obtém métricas básicas
  Future<Map<String, dynamic>> getMetrics() async {
    final events = await _getStoredEvents();
    final errors = await _getStoredErrors();

    return {
      'total_events': events.length,
      'total_errors': errors.length,
      'critical_events': events.where((e) => e['isCritical'] == true).length,
      'critical_errors': errors.where((e) => e['isCritical'] == true).length,
      'last_event': events.isNotEmpty ? events.last : null,
      'last_error': errors.isNotEmpty ? errors.last : null,
    };
  }
}

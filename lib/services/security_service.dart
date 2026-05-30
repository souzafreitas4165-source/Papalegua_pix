import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:papaleguas_pix/services/encryption_service.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final _sessionTimeout = const Duration(minutes: 30);
  DateTime? _lastActivity;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  late final SharedPreferences _prefs;

  // Chaves para armazenamento seguro
  static const _keyDeviceId = 'device_id';
  static const _keySessionToken = 'session_token';
  static const _keyLastActivity = 'last_activity';

  // Inicializa o serviço de segurança
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _generateDeviceId();
    _lastActivity = await _getLastActivity();
  }

  // Gera um ID único para o dispositivo
  Future<void> _generateDeviceId() async {
    String? deviceId = _prefs.getString(_keyDeviceId);
    
    if (deviceId == null) {
      // Tenta obter um ID de hardware único
      String? deviceIdentifier;
      try {
        if (Platform.isAndroid) {
          var androidInfo = await _deviceInfo.androidInfo;
          deviceIdentifier = androidInfo.id;
        } else if (Platform.isIOS) {
          var iosInfo = await _deviceInfo.iosInfo;
          deviceIdentifier = iosInfo.identifierForVendor;
        }
      } catch (e) {
        debugPrint('Erro ao obter ID do dispositivo: $e');
      }
      
      // Se não conseguir obter um ID de hardware, gera um aleatório
      deviceId = deviceIdentifier ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Armazena o ID usando o serviço de criptografia
      final encryptedId = EncryptionService.encrypt(deviceId);
      await _prefs.setString(_keyDeviceId, encryptedId);
    }
  }

  // Gera um ID único baseado em características do dispositivo
  Future<String> _generateUniqueDeviceId() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String deviceId = '';
    
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
    }

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      final deviceData = {
        'brand': androidInfo.brand,
        'device': androidInfo.device,
        'id': androidInfo.id,
        'fingerprint': androidInfo.fingerprint,
        'deviceId': deviceId,
        'timestamp': timestamp,
      };
      final deviceDataStr = json.encode(deviceData);
      return sha256.convert(utf8.encode(deviceDataStr)).toString();
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      final deviceData = {
        'name': iosInfo.name,
        'model': iosInfo.model,
        'systemName': iosInfo.systemName,
        'identifierForVendor': iosInfo.identifierForVendor,
        'deviceId': deviceId,
        'timestamp': timestamp,
      };
      final deviceDataStr = json.encode(deviceData);
      return sha256.convert(utf8.encode(deviceDataStr)).toString();
    }

    // Fallback para outros sistemas
    final hash = sha256.convert(utf8.encode(timestamp + deviceId));
    return hash.toString();
  }

  // Verifica se a sessão expirou
  Future<bool> hasSessionExpired() async {
    final lastActivity = await _getLastActivity();
    if (lastActivity == null) return true;

    final now = DateTime.now();
    return now.difference(lastActivity) > _sessionTimeout;
  }

  // Atualiza o timestamp da última atividade
  void _updateLastActivity() {
    _lastActivity = DateTime.now();
    _prefs.setString(_keyLastActivity, _lastActivity!.toIso8601String());
  }

  // Recupera o timestamp da última atividade
  Future<DateTime?> _getLastActivity() async {
    final lastActivityStr = _prefs.getString(_keyLastActivity);
    if (lastActivityStr == null) return null;
    return DateTime.parse(lastActivityStr);
  }

  // Obtém o token de sessão
  Future<String?> getSessionToken() async {
    final encryptedToken = _prefs.getString(_keySessionToken);
    return encryptedToken != null ? EncryptionService.decrypt(encryptedToken) : null;
  }

  // Define o token de sessão
  Future<void> setSessionToken(String token) async {
    final encryptedToken = EncryptionService.encrypt(token);
    await _prefs.setString(_keySessionToken, encryptedToken);
    _updateLastActivity();
  }

  // Remove o token de sessão e limpa os dados
  Future<void> clearSession() async {
    await _prefs.remove(_keySessionToken);
    await _prefs.remove(_keyLastActivity);
    _lastActivity = null;
  }

  // Valida o dispositivo atual com múltiplas verificações
  Future<bool> isValidDevice() async {
    try {
      final storedDeviceId = _prefs.getString(_keyDeviceId);
      if (storedDeviceId == null) return false;

      final currentDeviceId = await _generateUniqueDeviceId();
      if (currentDeviceId != EncryptionService.decrypt(storedDeviceId)) return false;

      // Verificações adicionais de segurança
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        if (androidInfo.isPhysicalDevice == false) {
          return false; // Bloqueia emuladores
        }

        // Verifica se o dispositivo está rooteado
        if (await _isDeviceRooted()) return false;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        if (iosInfo.isPhysicalDevice == false) {
          return false; // Bloqueia simuladores
        }

        // Verifica se o dispositivo está jailbroken
        if (await _isDeviceJailbroken()) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Verifica se o dispositivo Android está rooteado
  Future<bool> _isDeviceRooted() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final tags = androidInfo.tags;
      final fingerprint = androidInfo.fingerprint;
      final buildTags = androidInfo.tags;

      // Verifica indicadores comuns de root
      if (tags.contains('test-keys')) return true;
      if (fingerprint.contains('generic')) return true;
      if (buildTags.contains('dev-keys')) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  // Verifica se o dispositivo iOS está jailbroken
  Future<bool> _isDeviceJailbroken() async {
    try {
      final iosInfo = await _deviceInfo.iosInfo;
      final systemName = iosInfo.systemName.toLowerCase();
      final systemVersion = iosInfo.systemVersion.toLowerCase();

      // Verifica indicadores comuns de jailbreak
      if (systemName.contains('cydia')) return true;
      if (systemVersion.contains('jailbreak')) return true;
      
      // Verifica se o dispositivo está em modo de desenvolvimento
      if (systemVersion.contains('simulator') || systemVersion.contains('emulator')) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Erro ao verificar jailbreak: $e');
      return false;
    }
  }
  
  // Atualiza a última atividade do usuário
  Future<void> updateLastActivity() async {
    _updateLastActivity();
  }
  
  // Verifica se o usuário está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getSessionToken();
    return token != null && token.isNotEmpty;
  }
}

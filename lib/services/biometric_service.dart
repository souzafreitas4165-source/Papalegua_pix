import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logging/logging.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal() {
    _init();
  }

  final LocalAuthentication _auth = LocalAuthentication();
  static const String _keyBiometricEnabled = 'biometric_enabled';
  final _encryptionKey = encrypt.Key.fromLength(32);
  final _iv = encrypt.IV.fromLength(16);
  final _logger = Logger('BiometricService');
  bool _isInitialized = false;
  
  Future<void> _init() async {
    try {
      // Verifica a disponibilidade uma vez durante a inicialização
      await isBiometricAvailable();
      _isInitialized = true;
    } catch (e) {
      _logger.severe('Erro ao inicializar BiometricService', e);
      rethrow;
    }
  }

  // Verifica se o dispositivo suporta biometria
  Future<bool> isBiometricAvailable() async {
    try {
      // No Windows, retorna false pois não há suporte nativo
      if (Platform.isWindows) {
        _logger.info('Windows não suporta autenticação biométrica nativa');
        return false;
      }

      // Verifica se o hardware suporta biometria
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      
      _logger.info('''
        Biometria disponível:
        - Pode verificar biometria: $canCheckBiometrics
        - Dispositivo suportado: $isDeviceSupported
      ''');

      if (!canCheckBiometrics || !isDeviceSupported) {
        _logger.warning('Dispositivo não suporta biometria ou não pode verificar');
        return false;
      }

      // Lista os tipos de biometria disponíveis
      final List<BiometricType> availableBiometrics = 
          await _auth.getAvailableBiometrics();
          
      _logger.info('Tipos de biometria disponíveis: $availableBiometrics');

      return availableBiometrics.isNotEmpty;
    } on PlatformException catch (e) {
      _logger.severe('Erro ao verificar disponibilidade de biometria', e);
      return false;
    } catch (e) {
      _logger.severe('Erro inesperado ao verificar biometria', e);
      return false;
    }
  }

  // Realiza a autenticação biométrica
  Future<bool> authenticate({String? localizedReason}) async {
    try {
      if (!_isInitialized) {
        await _init();
      }
      
      if (!await isBiometricAvailable()) {
        _logger.warning('Biometria não disponível para autenticação');
        return false;
      }

      _logger.info('Iniciando autenticação biométrica...');
      
      final result = await _auth.authenticate(
        localizedReason: localizedReason ?? 'Autentique-se para acessar o aplicativo',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );
      
      _logger.info('Resultado da autenticação: $result');
      return result;
      
    } on PlatformException catch (e) {
      _logger.severe('Erro na autenticação biométrica', e);
      return false;
    } catch (e) {
      _logger.severe('Erro inesperado na autenticação biométrica', e);
      return false;
    }
  }

  // Verifica se a biometria está habilitada nas preferências
  Future<bool> isBiometricEnabled() async {
    try {
      if (!_isInitialized) {
        await _init();
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      if (Platform.isWindows) {
        // No Windows, usa uma versão criptografada do SharedPreferences
        final encrypted = prefs.getString('${_keyBiometricEnabled}_encrypted');
        if (encrypted == null) {
          _logger.info('Nenhuma configuração de biometria encontrada');
          return false;
        }

        try {
          final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
          final decrypted = encrypter.decrypt64(encrypted, iv: _iv);
          final isEnabled = decrypted == 'true';
          _logger.info('Biometria ${isEnabled ? 'habilitada' : 'desabilitada'} nas preferências');
          return isEnabled;
        } catch (e) {
          _logger.warning('Erro ao descriptografar preferência de biometria', e);
          return false;
        }
      } else {
        final isEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
        _logger.info('Biometria ${isEnabled ? 'habilitada' : 'desabilitada'} nas preferências');
        return isEnabled;
      }
    } catch (e) {
      _logger.severe('Erro ao verificar status da biometria', e);
      return false;
    }
  }

  // Habilita ou desabilita a biometria nas preferências
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      if (!_isInitialized) {
        await _init();
      }
      
      _logger.info('${enabled ? 'Habilitando' : 'Desabilitando'} biometria...');
      
      // Se estiver habilitando, verifica se a biometria está disponível
      if (enabled) {
        final isAvailable = await isBiometricAvailable();
        if (!isAvailable) {
          _logger.warning('Não é possível habilitar biometria: recurso não disponível');
          return false;
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      bool saveSuccess = false;

      if (Platform.isWindows) {
        // No Windows, armazena de forma criptografada
        try {
          final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
          final encrypted = encrypter.encrypt(enabled.toString(), iv: _iv);
          saveSuccess = await prefs.setString(
            '${_keyBiometricEnabled}_encrypted', 
            encrypted.base64
          );
        } catch (e) {
          _logger.severe('Erro ao criptografar preferência de biometria', e);
          return false;
        }
      } else {
        saveSuccess = await prefs.setBool(_keyBiometricEnabled, enabled);
      }
      
      if (saveSuccess) {
        _logger.info('Biometria ${enabled ? 'habilitada' : 'desabilitada'} com sucesso');
      } else {
        _logger.warning('Falha ao salvar preferência de biometria');
      }
      
      return saveSuccess;
      
    } catch (e) {
      _logger.severe('Erro ao ${enabled ? 'habilitar' : 'desabilitar'} biometria', e);
      return false;
    }
  }
  
  // Verifica se o dispositivo tem biometria configurada
  Future<bool> hasEnrolledBiometrics() async {
    try {
      if (!_isInitialized) {
        await _init();
      }
      
      if (Platform.isWindows) return false;
      
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      
      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
      
    } catch (e) {
      _logger.severe('Erro ao verificar biometrias cadastradas', e);
      return false;
    }
  }
}

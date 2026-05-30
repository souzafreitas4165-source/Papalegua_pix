import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class SecurityCheckerService {
  static final SecurityCheckerService _instance =
      SecurityCheckerService._internal();
  factory SecurityCheckerService() => _instance;
  SecurityCheckerService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final _channel = const MethodChannel('security_checker');

  // Lista de apps maliciosos conhecidos
  final List<String> _knownMaliciousApps = [
    'com.cheatengine',
    'com.xposed.installer',
    'de.robv.android.xposed.installer',
    'com.saurik.substrate',
    'com.zachspong.temprootremovejb',
    'com.amphoras.hidemyroot',
    'com.formyhm.hideroot',
    'com.koushikdutta.superuser',
    'eu.chainfire.supersu',
  ];

  // Verifica todas as ameaças de segurança
  Future<SecurityCheckResult> checkSecurityThreats() async {
    final result = SecurityCheckResult();

    // Se estiver na web, retorna resultado padrão sem ameaças
    if (kIsWeb) {
      return result;
    }

    try {
      if (Platform.isAndroid) {
        result.isEmulator = await _isEmulator();
        result.isRooted = await _isDeviceRooted();
        result.hasMaliciousApps = await _hasMaliciousApps();
        result.isDebugBuild = await _isDebugBuild();
      } else if (Platform.isIOS) {
        result.isEmulator = await _isEmulator();
        result.isJailbroken = await _isDeviceJailbroken();
        result.isDebugBuild = await _isDebugBuild();
      }
    } catch (e) {
      // Em caso de erro na verificação, assume que não há ameaças
      debugPrint('Erro ao verificar ameaças: $e');
    }

    return result;
  }

  // Verifica se é um emulador
  Future<bool> _isEmulator() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return !androidInfo.isPhysicalDevice ||
          androidInfo.brand.toLowerCase().contains('generic') ||
          androidInfo.model.toLowerCase().contains('sdk');
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return !iosInfo.isPhysicalDevice;
    }
    return false;
  }

  // Verifica se o dispositivo Android está rooteado
  Future<bool> _isDeviceRooted() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidInfo = await _deviceInfo.androidInfo;

      // Verifica indicadores comuns de root
      if (androidInfo.tags.contains('test-keys')) return true;
      if (androidInfo.bootloader.contains('unlocked')) return true;

      // Verifica arquivos comuns de root
      final commonRootFiles = [
        '/system/app/Superuser.apk',
        '/system/xbin/su',
        '/system/bin/su',
        '/sbin/su',
        '/system/su',
        '/system/bin/.ext/.su',
      ];

      for (final path in commonRootFiles) {
        if (await File(path).exists()) return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Verifica se o dispositivo iOS está jailbroken
  Future<bool> _isDeviceJailbroken() async {
    if (!Platform.isIOS) return false;

    try {
      // Verifica arquivos comuns de jailbreak
      final jailbreakPaths = [
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/usr/bin/ssh',
      ];

      for (final path in jailbreakPaths) {
        if (await File(path).exists()) return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Verifica se há apps maliciosos instalados
  Future<bool> _hasMaliciousApps() async {
    if (!Platform.isAndroid) return false;

    try {
      // Verifica apps maliciosos conhecidos
      final result = await _channel.invokeMethod('checkMaliciousApps', {
        'packages': _knownMaliciousApps,
      });

      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Verifica se é uma build de debug
  Future<bool> _isDebugBuild() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.packageName.toLowerCase().contains('debug') ||
          packageInfo.packageName.endsWith('.debug');
    } catch (e) {
      return false;
    }
  }
}

class SecurityCheckResult {
  bool isEmulator = false;
  bool isRooted = false;
  bool isJailbroken = false;
  bool hasMaliciousApps = false;
  bool isDebugBuild = false;

  bool get hasThreats =>
      isEmulator ||
      isRooted ||
      isJailbroken ||
      hasMaliciousApps ||
      isDebugBuild;

  List<String> get threatDescriptions {
    final threats = <String>[];
    if (isEmulator) threats.add('Dispositivo é um emulador');
    if (isRooted) threats.add('Dispositivo está rooteado');
    if (isJailbroken) threats.add('Dispositivo está jailbroken');
    if (hasMaliciousApps) threats.add('Apps maliciosos detectados');
    if (isDebugBuild) threats.add('Versão de debug do aplicativo');
    return threats;
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:papaleguas_pix/services/encryption_service.dart';

class CacheService {
  static const String _lastUpdatePrefix = 'last_update_';

  // Função para comprimir dados
  static List<int> _compressData(String data) {
    final bytes = utf8.encode(data);
    return GZipEncoder().encode(bytes)!;
  }

  // Função para descomprimir dados
  static String _decompressData(List<int> compressed) {
    final decompressed = GZipDecoder().decodeBytes(compressed);
    return utf8.decode(decompressed);
  }

  // Função para limpar o cache de uma chave específica
  static Future<void> _clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      await prefs.remove('${key}_expiry');
      await prefs.remove(_lastUpdatePrefix + key);
    } catch (e) {
      debugPrint('Erro ao limpar cache: $e');
    }
  }

  // Salva dados no cache com opção de compressão e criptografia
  static Future<void> saveToCache(
    String key,
    dynamic data, {
    Duration? duration,
    bool compress = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data);

      String dataToStore = jsonData;
      if (compress && jsonData.length > 1000) {
        final compressed = _compressData(jsonData);
        dataToStore = base64Encode(compressed);
      }
      
      // Criptografa os dados antes de salvar
      dataToStore = EncryptionService.encrypt(dataToStore);

      await prefs.setString(key, dataToStore);
      await prefs.setString(
          _lastUpdatePrefix + key, DateTime.now().toIso8601String());

      if (duration != null) {
        await prefs.setString(
          '${key}_expiry',
          DateTime.now().add(duration).toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar no cache: $e');
    }
  }

  // Obtém dados do cache, descriptografando e descomprimindo se necessário
  static Future<dynamic> getFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(key);
      if (data == null) return null;

      // Verifica expiração
      final expiryStr = prefs.getString('${key}_expiry');
      if (expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (DateTime.now().isAfter(expiry)) {
          await _clearCache(key);
          return null;
        }
      }

      try {
        // Tenta descriptografar e decodificar como JSON
        final decrypted = EncryptionService.decrypt(data);
        return jsonDecode(decrypted);
      } catch (e) {
        // Se falhar, tenta descomprimir
        try {
          final decrypted = EncryptionService.decrypt(data);
          final compressed = base64Decode(decrypted);
          final decompressed = _decompressData(compressed);
          return jsonDecode(decompressed);
        } catch (e) {
          debugPrint('Erro ao descomprimir dados do cache: $e');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Erro ao ler do cache: $e');
      return null;
    }
  }

  // Obtém a data da última atualização de uma chave
  static Future<DateTime?> getLastUpdateTime(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdatePrefix + key);
      if (lastUpdate == null) return null;
      return DateTime.parse(lastUpdate);
    } catch (e) {
      debugPrint('Erro ao ler última atualização do cache: $e');
      return null;
    }
  }
}

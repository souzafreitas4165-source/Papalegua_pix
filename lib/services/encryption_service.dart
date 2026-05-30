import 'dart:convert';

import 'package:flutter/material.dart';

class EncryptionService {
  // Codifica os dados em base64
  static String encrypt(String plaintext) {
    try {
      final bytes = utf8.encode(plaintext);
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Erro ao codificar: $e');
      rethrow;
    }
  }

  // Decodifica os dados de base64
  static String decrypt(String ciphertext) {
    try {
      final bytes = base64Decode(ciphertext);
      return utf8.decode(bytes);
    } catch (e) {
      debugPrint('Erro ao decodificar: $e');
      rethrow;
    }
  }
}

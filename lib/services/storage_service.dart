import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Pega uma imagem da galeria
  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao selecionar imagem: $e');
    }
  }

  // Pega um documento (PDF, DOC, etc.)
  Future<File?> pickDocument() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (file != null) {
        return File(file.path);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao selecionar documento: $e');
    }
  }

  // Faz upload de um arquivo para o storage do Supabase
  Future<String> uploadFile({
    required File file,
    required String bucket,
    String? userId,
  }) async {
    try {
      final fileName = '${userId ?? 'temp'}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      
      await _supabase.storage
          .from(bucket)
          .upload(fileName, file);
          
      return _supabase.storage
          .from(bucket)
          .getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Erro ao fazer upload do arquivo: $e');
    }
  }

  // Remove um arquivo do storage
  Future<void> removeFile(String url, String bucket) async {
    try {
      final fileName = url.split('/').last;
      await _supabase.storage
          .from(bucket)
          .remove([fileName]);
    } catch (e) {
      throw Exception('Erro ao remover arquivo: $e');
    }
  }
}

bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,4}$');
  return emailRegex.hasMatch(email);
}

bool isValidCPF(String cpf) {
  // Remove caracteres não numéricos
  final cpfNumeros = cpf.replaceAll(RegExp(r'[^0-9]'), '');
  
  // Verifica se tem 11 dígitos
  if (cpfNumeros.length != 11) return false;
  
  // Verifica se todos os dígitos são iguais
  if (RegExp(r'^(\d)\1{10}$').hasMatch(cpfNumeros)) return false;
  
  // Validação do primeiro dígito verificador
  int soma = 0;
  for (int i = 0; i < 9; i++) {
    soma += int.parse(cpfNumeros[i]) * (10 - i);
  }
  int dig1 = 11 - (soma % 11);
  if (dig1 >= 10) dig1 = 0;
  if (dig1 != int.parse(cpfNumeros[9])) return false;
  
  // Validação do segundo dígito verificador
  soma = 0;
  for (int i = 0; i < 10; i++) {
    soma += int.parse(cpfNumeros[i]) * (11 - i);
  }
  int dig2 = 11 - (soma % 11);
  if (dig2 >= 10) dig2 = 0;
  if (dig2 != int.parse(cpfNumeros[10])) return false;
  
  return true;
}

bool isValidCNPJ(String cnpj) {
  // Remove caracteres não numéricos
  final cnpjNumeros = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
  
  // Verifica se tem 14 dígitos
  if (cnpjNumeros.length != 14) return false;
  
  // Verifica se todos os dígitos são iguais
  if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpjNumeros)) return false;
  
  // Validação do primeiro dígito verificador
  int peso = 2;
  int soma = 0;
  for (int i = 11; i >= 0; i--) {
    soma += int.parse(cnpjNumeros[i]) * peso;
    peso = (peso == 9) ? 2 : peso + 1;
  }
  int dig1 = (soma % 11 < 2) ? 0 : 11 - (soma % 11);
  if (dig1 != int.parse(cnpjNumeros[12])) return false;
  
  // Validação do segundo dígito verificador
  peso = 2;
  soma = 0;
  for (int i = 12; i >= 0; i--) {
    soma += int.parse(cnpjNumeros[i]) * peso;
    peso = (peso == 9) ? 2 : peso + 1;
  }
  int dig2 = (soma % 11 < 2) ? 0 : 11 - (soma % 11);
  if (dig2 != int.parse(cnpjNumeros[13])) return false;
  
  return true;
}

bool isValidDocument(String document) {
  // Remove caracteres não numéricos
  final doc = document.replaceAll(RegExp(r'[^0-9]'), '');
  
  // Verifica se é CPF (11 dígitos) ou CNPJ (14 dígitos)
  if (doc.length == 11) {
    return isValidCPF(document);
  } else if (doc.length == 14) {
    return isValidCNPJ(document);
  }
  return false;
}

bool isValidPhoneBR(String phone) {
  // Remove caracteres não numéricos
  final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
  
  // Para celular, deve ter 11 dígitos (2 DDD + 9 + 8 dígitos)
  if (cleaned.length != 11) return false;
  
  // Verifica se o DDD é válido (11 a 99, exceto os que não existem)
  final ddd = int.parse(cleaned.substring(0, 2));
  if (ddd < 11 || ddd > 99) return false;
  
  // Verifica se o nono dígito é 9 (padrão para celular)
  if (cleaned[2] != '9') {
    return false;
  }
  
  // Verifica se os próximos dígitos são válidos (não podem ser todos iguais)
  final phoneNumber = cleaned.substring(2);
  if (RegExp(r'^(\d)\1+$').hasMatch(phoneNumber)) {
    return false;
  }
  
  // Se passou por todas as validações, o número é válido
  return true;
}

bool isValidName(String name) {
  final nameRegex = RegExp(r'^[a-zA-ZÀ-ÿ\s]{5,}(?: [a-zA-ZÀ-ÿ\s]+){1,}$');
  return nameRegex.hasMatch(name) && name.trim().split(' ').length >= 2;
}

// Verifica se o e-mail já está cadastrado
Future<bool> isEmailRegistered(String email) async {
  try {
    // Implemente a verificação real no seu backend
    // Este é apenas um exemplo de implementação
    await Future.delayed(const Duration(milliseconds: 500));
    return false; // Altere para a verificação real
  } catch (e) {
    throw Exception('Erro ao verificar e-mail: $e');
  }
}

// Formata o CPF/CNPJ para exibição
String formatDocument(String document) {
  final doc = document.replaceAll(RegExp(r'[^0-9]'), '');
  
  if (doc.length == 11) {
    // Formata CPF: 000.000.000-00
    return '${doc.substring(0, 3)}.${doc.substring(3, 6)}.${doc.substring(6, 9)}-${doc.substring(9)}';
  } else if (doc.length == 14) {
    // Formata CNPJ: 00.000.000/0000-00
    return '${doc.substring(0, 2)}.${doc.substring(2, 5)}.${doc.substring(5, 8)}/${doc.substring(8, 12)}-${doc.substring(12)}';
  }
  
  return document; // Retorna o original se não for CPF nem CNPJ
}

// Valida se a senha atende aos requisitos mínimos
bool isStrongPassword(String password) {
  // Pelo menos 8 caracteres, 1 letra maiúscula, 1 minúscula, 1 número e 1 caractere especial
  final strongRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
  return strongRegex.hasMatch(password);
}
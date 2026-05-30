# 🚀 Guia de Contribuição para o Urubu PIX

Obrigado por considerar contribuir para o Urubu PIX! Sua ajuda é essencial para tornar este projeto cada vez melhor. Este guia irá ajudá-lo a começar a contribuir de forma eficaz.

## 📋 Antes de Começar

1. 📖 Leia nosso [Código de Conduta](CODE_OF_CONDUCT.md)
2. 🔍 Verifique as [issues abertas](https://github.com/seu-usuario/urubu_pix/issues) para encontrar algo para trabalhar
3. 🏷️ Para iniciantes, procure por issues com a tag `good first issue`
4. 💡 Se tiver uma nova ideia, abra uma issue para discutirmos antes de começar

## 🛠 Configuração do Ambiente

### Requisitos Mínimos
- Flutter 3.16.0+
- Dart 3.0.0+
- Git 2.30.0+
- Android Studio / Xcode (para desenvolvimento móvel)
- Node.js 16+ (para Supabase CLI)

### Passo a Passo

1. **Faça um fork** do repositório
2. **Clone** o repositório:
   ```bash
   git clone https://github.com/seu-usuario/urubu_pix.git
   cd urubu_pix
   ```
3. **Configure as variáveis de ambiente**:
   ```bash
   cp .env.example .env
   # Edite o .env com suas credenciais do Supabase
   ```
4. **Instale as dependências**:
   ```bash
   flutter pub get
   ```
5. **Execute o aplicativo**:
   ```bash
   flutter run
   ```

## 🔄 Fluxo de Trabalho

1. **Atualize seu fork**
   ```bash
   git checkout main
   git pull upstream main
   ```

2. **Crie uma branch** descritiva:
   ```bash
   git checkout -b tipo/descricao-curta
   # Exemplos:
   # git checkout -b feat/adiciona-login-biometrico
   # git checkout -b fix/corrige-calculo-saldo
   # git checkout -b docs/atualiza-readme
   ```

3. **Desenvolva sua feature**
   - Siga as [diretrizes de estilo](#-diretrizes-de-código)
   - Escreva testes para seu código
   - Atualize a documentação quando necessário

4. **Execute os testes**:
   ```bash
   # Testes unitários
   flutter test
   
   # Testes de integração
   flutter test integration_test/
   
   # Verifique a formatação
   flutter format --set-exit-if-changed .
   
   # Analise o código
   flutter analyze
   ```

5. **Faça o commit** seguindo as convenções:
   ```bash
   git add .
   git commit -m "tipo(escopo): mensagem descritiva"
   ```
   
   Tipos válidos: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

6. **Envie suas alterações**:
   ```bash
   git push origin sua-branch
   ```

7. **Abra um Pull Request**
   - Preencha o template de PR
   - Inclua capturas de tela quando aplicável
   - Aguarde a revisão da equipe

## 🎨 Diretrizes de Código

### Estrutura
- Siga a arquitetura em camadas (UI, Domínio, Dados, Infraestrutura)
- Mantenha os componentes pequenos e focados
- Use nomes descritivos para variáveis e funções

### Estilo
- Siga o [Effective Dart](https://dart.dev/guides/language/effective-dart/style)
- Use 2 espaços para indentação
- Linhas com no máximo 80 caracteres
- Comente o código complexo

### Testes
- Cubra casos de sucesso e falha
- Teste os estados da UI
- Use mocks para dependências externas

## 🤝 Processo de Revisão

1. Um mantenedor revisará seu PR
2. Podem ser solicitadas alterações
3. Após aprovação, seu código será mesclado

## 📝 Reportando Bugs

Use o template de issue e inclua:
- Descrição clara
- Passos para reproduzir
- Comportamento esperado vs atual
- Capturas de tela (se aplicável)
- Versão do app e dispositivo

## 💡 Sugerindo Melhorias

Adoramos novas ideias! Abra uma issue com:
- Descrição detalhada
- Casos de uso
- Benefícios esperados
- Exemplos de implementação (se possível)

## 📚 Recursos Úteis

- [Documentação do Flutter](https://flutter.dev/docs)
- [Guia de Estilo Dart](https://dart.dev/guides/language/effective-dart)
- [Supabase Docs](https://supabase.com/docs)
- [Padrões de Commit](https://www.conventionalcommits.org/)

## 🙌 Agradecimentos

Obrigado por ajudar a melhorar o Urubu PIX! Sua contribuição faz a diferença 💜

---

*Este guia foi inspirado em vários projetos de código aberto populares.*
   Exemplos de mensagens de commit:
   - `feat(home): adiciona botão de atualizar saldo`
   - `fix(auth): corrige validação de senha`
   - `docs: atualiza documentação do README`

5. **Envie as alterações** para o seu fork:
   ```bash
   git push origin nome-da-sua-branch
   ```

6. **Abra um Pull Request** para o branch `main` do repositório original

## 📝 Convenções de Código

### Nomenclatura
- Use nomes descritivos para variáveis, funções e classes
- Siga as convenções de nomenclatura do Dart:
  - Classes: `PascalCase`
  - Variáveis e funções: `camelCase`
  - Constantes: `UPPER_CASE`

### Formatação
- Use `dart format` para manter a formatação consistente
- Linhas não devem ultrapassar 80 caracteres
- Use ponto e vírgula no final das declarações

### Documentação
- Documente todas as classes e métodos públicos
- Use DartDoc para documentação de API
- Mantenha os comentários atualizados com o código

## 🧪 Testes

### Escrevendo Testes
- Escreva testes para novas funcionalidades
- Mantenha a cobertura de testes acima de 80%
- Use mocks para dependências externas

### Executando Testes
```bash
# Todos os testes
flutter test

# Testes específicos
flutter test test/unit/auth_service_test.dart

# Com cobertura
flutter test --coverage
```

## 📦 Gerenciamento de Dependências
- Atualize as dependências regularmente
- Use versões específicas no `pubspec.yaml`
- Documente alterações significativas nas dependências

## 🚀 Implantação

### Android
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ipa --export-options-plist=ios/exportOptions.plist
```

## 📄 Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob a [Licença MIT](LICENSE).

## 🙋 Dúvidas?

Se você tiver dúvidas ou precisar de ajuda, abra uma issue no repositório ou entre em contato com a equipe de manutenção.

Obrigado por contribuir para o Urubu PIX! 🎉

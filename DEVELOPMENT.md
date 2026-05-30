# 🛠️ Guia do Desenvolvedor - Urubu PIX

Este documento fornece informações técnicas detalhadas para desenvolvedores que desejam contribuir com o projeto Urubu PIX.

## 📱 Visão Geral Técnica

O Urubu PIX é um aplicativo de banco digital desenvolvido em Flutter com backend em Supabase. Ele permite transferências PIX, gerenciamento de contas e visualização de extratos.

### 🔧 Tecnologias Principais

- **Frontend**: Flutter 3.16.0+
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime)
- **Autenticação**: OAuth2, JWT, Biometria
- **Banco de Dados**: PostgreSQL 14+
- **CI/CD**: GitHub Actions
- **Testes**: Unitários, Widget, Integração

## 🏗️ Arquitetura

O Urubu PIX segue uma arquitetura em camadas com separação clara de responsabilidades:

### 1. Camada de Apresentação (UI)
- **Componentes**: Widgets reutilizáveis e telas
- **Controladores**: Gerenciamento de estado com Provider
- **Navegação**: Go Router para roteamento
- **Temas**: Suporte a temas claro/escuro

### 2. Camada de Domínio
- **Casos de Uso**: Lógica de negócios
- **Modelos**: Entidades do domínio
- **Validadores**: Regras de validação
- **Serviços**: Lógica de negócios reutilizável

### 3. Camada de Dados
- **Repositórios**: Abstração do acesso a dados
- **Modelos**: DTOs e entidades
- **Mapeadores**: Conversão entre modelos
- **Fontes**: Local (Hive) e Remota (Supabase)

### 4. Camada de Infraestrutura
- **API Client**: Dio para requisições HTTP
- **Autenticação**: Supabase Auth
- **Armazenamento**: Hive (local) e Supabase Storage
- **Monitoramento**: Sentry para erros

## 🔄 Padrões de Projeto

| Padrão | Uso |
|--------|-----|
| **Repository** | Abstração do acesso a dados |
| **Provider** | Gerenciamento de estado |
| **Service Locator** | Injeção de dependências |
| **Factory** | Criação de objetos complexos |
| **Builder** | Construção de widgets complexos |
| **Singleton** | Serviços globais |
| **Observer** | Monitoramento de estado |

## 🧩 Estrutura de Pastas

```
lib/
├── main.dart                     # Ponto de entrada
├── app/                          # Configuração do app
│   ├── app.dart                 # Configuração principal
│   ├── router.dart              # Configuração de rotas
│   └── theme.dart               # Temas e estilos
│
├── core/                       # Código central
│   ├── constants/               # Constantes globais
│   ├── errors/                  # Tratamento de erros
│   ├── network/                 # Configuração de rede
│   └── utils/                   # Utilitários gerais
│
├── data/                       # Camada de dados
│   ├── datasources/             # Fontes de dados
│   ├── models/                  # Modelos de dados
│   └── repositories/            # Implementações de repositórios
│
├── domain/                     # Lógica de negócios
│   ├── entities/                # Entidades de domínio
│   ├── repositories/            # Interfaces de repositórios
│   └── usecases/                # Casos de uso
│
├── presentation/               # Interface do usuário
│   ├── screens/                 # Telas do app
│   │   ├── auth/                # Autenticação
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   │
│   │   ├── dashboard/         # Dashboard
│   │   │   └── dashboard_screen.dart
│   │   │
│   │   ├── transfers/         # Transferências
│   │   │   ├── transfer_screen.dart
│   │   │   └── transfer_detail_screen.dart
│   │   │
│   │   └── settings/          # Configurações
│   │       └── settings_screen.dart
│   │
│   ├── widgets/               # Componentes reutilizáveis
│   │   ├── common/             # Componentes comuns
│   │   └── shared/             # Componentes compartilhados
│   │
│   └── providers/             # Gerenciamento de estado
│       ├── auth_provider.dart
│       └── theme_provider.dart
│
└── l10n/                       # Internacionalização
    ├── intl_en.arb
    └── intl_pt.arb
```
│   │   └── history_screen.dart
│   └── profile/            # Perfil
│       └── profile_screen.dart
├── widgets/                # Componentes UI reutilizáveis
│   ├── common/             # Componentes gerais
│   │   ├── buttons/
│   │   ├── dialogs/
│   │   └── loaders/
│   ├── saldo_card.dart     # Card de saldo
│   └── transaction_list.dart # Lista de transações
├── services/               # Serviços de negócios
│   ├── api_service.dart    # Comunicação com API
│   └── auth_service.dart   # Autenticação
└── utils/                  # Utilitários
    ├── constants.dart      # Constantes
    ├── formatters.dart     # Formatadores
    └── validators.dart     # Validações

test/                      # Testes automatizados
├── mocks/                 # Mocks para testes
├── screens/               # Testes de tela
└── widgets/               # Testes de widgets
```

## 🛠️ Configuração do Ambiente

1. **Configuração do Ambiente Flutter**
   ```bash
   flutter doctor
   flutter pub get
   ```

2. **Variáveis de Ambiente**
   Crie um arquivo `.env` na raiz do projeto:
   ```
   # Configurações da API
   API_BASE_URL=your_api_url_here
   
   # Chaves de API
   GOOGLE_MAPS_API_KEY=your_google_maps_key
   ```

3. **Geração de Código**
   Execute o build_runner para gerar códigos:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## 🧪 Testes

### Estratégia de Testes

1. **Testes Unitários**
   - Testam unidades individuais de código
   - Rápidos e isolados
   ```bash
   flutter test test/unit/
   ```

2. **Testes de Widget**
   - Testam a interface do usuário
   - Verificam a renderização e interações
   ```bash
   flutter test test/widgets/
   ```

3. **Testes de Integração**
   - Testam fluxos completos
   - Verificam a integração entre componentes
   ```bash
   flutter test integration_test/
   ```

### Boas Práticas

- Mantenha os testes independentes
- Use mocks para dependências externas
- Siga o padrão AAA (Arrange-Act-Assert)
- Nomeie os testes de forma descritiva
- Mantenha a cobertura de testes acima de 80%

### Geração de Cobertura

```bash
flutter test --coverage
# Gera relatório em HTML
genhtml coverage/lcov.info -o coverage/html
```

## 🔄 Padrões de Código

1. **Nomenclatura**
   - Classes: `PascalCase`
   - Variáveis e funções: `camelCase`
   - Constantes: `UPPER_CASE`

2. **Documentação**
   - Documente todas as classes públicas
   - Use DartDoc para documentação de API
   - Mantenha comentários explicativos para lógicas complexas

3. **Estilo**
   - Siga as diretrizes oficiais do Flutter
   - Use `dart format` para formatação consistente

## 🔒 Segurança

### Armazenamento Seguro
- Use `flutter_secure_storage` para dados sensíveis
- Nunca armazene tokens ou senhas em texto puro
- Utilize o Keychain (iOS) e o Keystore (Android) para armazenamento seguro

### Validação de Dados
- Valide todas as entradas do usuário no cliente e no servidor
- Use expressões regulares para validação de formatos
- Implemente sanitização de dados para prevenir injeção

## 🔒 Segurança

### Autenticação e Autorização
- Tokens JWT com expiração curta (15min)
- Refresh tokens com rotação
- Validação de sessão em todas as requisições
- Proteção contra ataques CSRF

### Dados Sensíveis
- Criptografia em repouso (AES-256)
- Dados sensíveis nunca são armazenados em log
- Máscara de dados sensíveis na UI
- Validação de entrada em todas as camadas

### Comunicação Segura
- HTTPS obrigatório para todas as requisições
- SSL Pinning implementado
- Validação estrita de certificados
- Headers de segurança HTTP
- CORS configurado de forma restritiva

## 🚀 Performance

### Otimizações
- Cache inteligente de dados
- Paginação de listas longas
- Compressão de imagens
- Carregamento preguiçoso de recursos

### Monitoramento
- Logs de desempenho
- Rastreamento de erros com Sentry
- Métricas de uso de memória
- Tempo de carregamento das telas

## 📦 Dependências Principais

### Frontend
- `provider`: Gerenciamento de estado
- `dio`: Cliente HTTP
- `hive`: Armazenamento local
- `intl`: Internacionalização
- `flutter_local_notifications`: Notificações
- `qr_code_scanner`: Leitor de QR Code
- `flutter_svg`: Renderização de SVGs
- `cached_network_image`: Cache de imagens

### Backend (Supabase)
- PostgreSQL 14+
- Row Level Security (RLS)
- Funções Edge
- Armazenamento de arquivos
- Autenticação e Autorização

## 🔄 Fluxo de Desenvolvimento

1. **Configuração Inicial**
   ```bash
   # Instale as dependências
   flutter pub get
   
   # Execute os testes
   flutter test
   
   # Inicie o app em modo desenvolvimento
   flutter run -t lib/main_development.dart
   ```

2. **Variáveis de Ambiente**
   Crie um arquivo `.env` baseado no `.env.example`:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_anon_key
   SENTRY_DSN=your_sentry_dsn
   ```

3. **Supabase Local**
   ```bash
   # Instale o CLI do Supabase
   npm install -g supabase
   
   # Inicie o ambiente local
   supabase start
   ```

## 🧪 Testes

### Tipos de Testes
- **Unitários**: Testes de unidade isolados
- **Widget**: Testes de componentes UI
- **Integração**: Testes de fluxo completo
- **Golden**: Testes de snapshot

### Executando Testes
```bash
# Todos os testes
flutter test

# Testes específicos
flutter test test/unit/auth_test.dart

# Testes com cobertura
flutter test --coverage
```

## 📚 Documentação Adicional

- [Guia de Estilo](STYLE_GUIDE.md)
- [Documentação da API](API_DOCS.md)
- [Guia de Contribuição](CONTRIBUTING.md)
- [Código de Conduta](CODE_OF_CONDUCT.md)

## 🤝 Suporte

Encontrou um problema ou tem dúvidas?
- Abra uma [issue](https://github.com/seu-usuario/urubu_pix/issues)
- Consulte as [FAQs](docs/FAQs.md)
- Entre no nosso [Discord](https://discord.gg/urubupix)

### Autenticação
- Implemente autenticação de dois fatores
- Use refresh tokens
- Implemente bloqueio após várias tentativas falhas
- Registre atividades suspeitas

### Privacidade
- Minimize a coleta de dados
- Obtenha consentimento explícito do usuário
- Cumpra a LGPD/GDPR

## 📦 Gerenciamento de Dependências

1. **Atualização de Pacotes**
   ```bash
   flutter pub outdated
   flutter pub upgrade --major-versions
   ```

2. **Verificação de Vulnerabilidades**
   ```bash
   flutter pub upgrade --dry-run
   ```

## 🚀 Implantação

### Pré-requisitos
- Certifique-se de que todos os testes estão passando
- Atualize o número da versão no `pubspec.yaml`
- Atualize o CHANGELOG.md

### Android
1. Gere a chave de assinatura (se ainda não tiver)
2. Configure o `key.properties`
3. Gere o bundle de release:
   ```bash
   flutter build appbundle --release
   ```
4. Envie para a Google Play Console

### iOS
1. Atualize o número da versão no `Info.plist`
2. Gere o arquivo IPA:
   ```bash
   flutter build ipa --export-options-plist=ios/exportOptions.plist
   ```
3. Envie para o App Store Connect

### Atualizações
- Mantenha as dependências atualizadas
- Documente as mudanças significativas
- Comunique as atualizações aos usuários

## 🐛 Depuração

1. **Logs**
   ```dart
   import 'dart:developer' as developer;
   
   void someMethod() {
     developer.log('Debug log', name: 'my.app.category');
   }
   ```

2. **Observação de Mudanças**
   ```bash
   flutter pub run build_runner watch --delete-conflicting-outputs
   ```

## 🤝 Contribuição

1. Siga o [Código de Conduta](CODE_OF_CONDUCT.md)
2. Crie uma branch descritiva para suas alterações
3. Escreva testes para novas funcionalidades
4. Atualize a documentação conforme necessário
5. Envie um Pull Request com uma descrição clara

## 📝 Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

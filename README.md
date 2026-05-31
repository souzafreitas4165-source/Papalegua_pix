# 🏦 Papalegua PIX - Banco Digital

[![Flutter](https://img.shields.io/badge/Flutter-3.16.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0.0-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-181818?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Status: Em Desenvolvimento](https://img.shields.io/badge/Status-Em%20Desenvolvimento-orange?style=for-the-badge)]()

Um aplicativo de banco digital moderno desenvolvido em Flutter, oferecendo uma solução completa para gerenciamento financeiro pessoal, com foco em transferências via PIX, histórico de transações e visualização de saldo em tempo real.

## ✨ Funcionalidades Principais

- 💰 **Gerenciamento de Conta**
  - Visualização de saldo em tempo real
  - Extrato detalhado de transações
  - Perfil do usuário personalizável
  - Atualização automática de saldo

- 🔄 **Operações Financeiras**
  - Transferências PIX instantâneas
  - Busca de destinatários por CPF, email ou telefone
  - Histórico de transações detalhado
  - Comprovantes de transferência
  - Conversão automática de moedas

- 🏦 **Integração Bancária**
  - Conexão segura via Supabase
  - Transações em tempo real
  - Sincronização automática de dados
  - Backup em nuvem seguro

- 🔒 **Segurança Avançada**
  - Autenticação JWT
  - Criptografia de ponta a ponta
  - Validação em tempo real
  - Proteção contra fraudes
  - Logs de auditoria detalhados

- 🌐 **Experiência do Usuário**
  - Interface moderna e intuitiva
  - Tema escuro/light
  - Animações fluidas
  - Feedback visual imediato

## 🚀 Começando

### Pré-requisitos

- Flutter SDK 3.16.0 ou superior
- Dart SDK 3.0.0 ou superior
- Node.js 16.x ou superior (para o Supabase CLI)
- Conta no [Supabase](https://supabase.com/)
- Android Studio / Xcode (para desenvolvimento móvel)
- VS Code (recomendado) com extensões Flutter e Dart

### Configuração do Ambiente

1. **Configuração do Supabase**
   - Crie um novo projeto em [app.supabase.com](https://app.supabase.com/)
   - Configure as tabelas necessárias (veja em `supabase/migrations`)
   - Obtenha as chaves de API nas configurações do projeto

2. **Variáveis de Ambiente**
   Crie um arquivo `.env` na raiz do projeto com:
   ```
   SUPABASE_URL=sua_url_do_supabase
   SUPABASE_ANON_KEY=sua_chave_anonima
   ```

### Instalação

1. **Clone o repositório**
   ```bash
   git clone https://github.com/seu-usuario/urubu_pix.git
   cd urubu_pix
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Execute o aplicativo**
   ```bash
   flutter run
   ```

## 🏗️ Estrutura do Projeto

```
lib/
├── main.dart               # Ponto de entrada do aplicativo
├── l10n/                   # Arquivos de internacionalização
│   └── intl_*.arb         # Arquivos de tradução
├── screens/                # Telas do aplicativo
│   ├── auth/               # Fluxo de autenticação
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/               # Tela inicial
│   │   └── home_screen.dart
│   ├── dashboard/          # Dashboard financeiro
│   │   └── dashboard_screen.dart
│   ├── transfers/          # Fluxo de transferências
│   │   ├── transfer_screen.dart
│   │   └── transfer_detail_screen.dart
│   ├── history/            # Histórico de transações
│   │   └── history_screen.dart
│   └── profile/            # Perfil do usuário
│       └── profile_screen.dart
├── widgets/                # Componentes reutilizáveis
│   ├── common/             # Componentes gerais
│   │   ├── buttons/
│   │   ├── dialogs/
│   │   └── loaders/
│   ├── saldo_card.dart     # Card de saldo
│   └── transaction_list.dart # Lista de transações
├── services/               # Camada de serviços
│   ├── api_service.dart    # Comunicação com a API
│   └── auth_service.dart   # Gerenciamento de autenticação
└── utils/                  # Utilitários
    ├── constants.dart      # Constantes do aplicativo
    ├── formatters.dart     # Formatadores de dados
    └── validators.dart     # Validações de formulário
```

## 🧪 Testes

O projeto inclui testes unitários e de widget para garantir a qualidade do código:

```bash
# Executar todos os testes
flutter test

# Executar testes específicos
flutter test test/screens/home_screen_test.dart
```

## 📦 Dependências Principais

| Pacote | Versão | Descrição |
|--------|--------|------------|
| `provider` | ^6.0.5 | Gerenciamento de estado |
| `http` | ^1.4.0 | Requisições HTTP |
| `shared_preferences` | ^2.2.0 | Armazenamento local |
| `intl` | ^0.19.0 | Internacionalização |
| `fl_chart` | ^0.66.0 | Gráficos |
| `mockito` | ^5.4.4 | Mocks para testes |
| `supabase_flutter` | ^2.9.0 | Backend como Serviço |
| `image_picker` | ^1.0.4 | Seleção de imagens |
| `url_launcher` | ^6.1.14 | Abertura de URLs |
| `google_fonts` | ^6.1.0 | Fontes personalizadas |
| `pdf` | ^3.10.8 | Geração de PDF |
| `flutter_local_notifications` | ^16.3.2 | Notificações locais |

## 🤝 Contribuição

1. Faça um Fork do projeto
2. Crie uma Branch para sua Feature (`git checkout -b feature/AmazingFeature`)
3. Adicione suas mudanças (`git add .`)
4. Comite suas mudanças (`git commit -m 'Add some AmazingFeature'`)
5. Faça o Push da Branch (`git push origin feature/AmazingFeature`)
6. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## ✉️ Contato

Seu Nome - [@seu_twitter](https://twitter.com/seu_twitter) - email@exemplo.com

Link do Projeto: [https://github.com/seu-usuario/urubu_pix](https://github.com/seu-usuario/urubu_pix)

## 📝 Notas de Atualização

### 1.2.0 (2025-05-24)
- 🚀 Sistema de Transferência PIX aprimorado
- 🔒 Melhorias na segurança das transações
- 🛠️ Correção de bugs críticos
- 📱 Melhorias na experiência do usuário
- ⚡ Otimizações de desempenho

### 1.1.0 (2025-05-20)
- 🔔 Adicionado suporte a notificações locais
- 🎨 Melhorias na interface do usuário
- ⚡ Otimização de desempenho
- 🐛 Correções de bugs menores

### 1.0.0 (2025-04-15)
- 🎉 Versão inicial do aplicativo
- 💸 Funcionalidades básicas de transferência PIX
- 📊 Dashboard com histórico de transações
- 🔐 Autenticação de usuários
- 👤 Perfil do usuário
- 🖨️ Geração de comprovantes em PDF

## 🛠️ Estrutura do Banco de Dados

### Tabela: `users`
- `user_id` (UUID, PK)
- `email` (text, unique)
- `nome` (text)
- `cpf` (text, unique)
- `telefone` (text)
- `created_at` (timestamp)

### Tabela: `accounts`
- `user_id` (UUID, FK -> users.user_id)
- `balance` (numeric)
- `created_at` (timestamp)
- `updated_at` (timestamp)

### Tabela: `transfers`
- `id` (UUID, PK)
- `user_id` (UUID, FK -> users.user_id)
- `destinatario` (text)
- `valor` (double precision)
- `moeda` (text)
- `valor_original` (double precision)
- `data` (timestamp with time zone)

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas alterações (`git commit -m 'Add some AmazingFeature'`)
4. Faça o push da branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## ✉️ Contato

Time de Desenvolvimento - [contato@urubupix.com](mailto:contato@urubupix.com)

---

Desenvolvido com ❤️ pelo Time Urubu PIX

# FlexBiz - Sistema de Gestão Multi-Tenant

Sistema de gestão completo para pequenos negócios, desenvolvido com Flutter e Supabase.

## 🚀 Funcionalidades do MVP

- ✅ Autenticação e cadastro de empresas
- ✅ Gestão de itens (produtos/serviços)
- ✅ Cadastro de clientes
- ✅ Criação e gerenciamento de pedidos
- ✅ Contas a receber (geração automática a partir de pedidos)
- ✅ Contas a pagar (lançamento manual)
- ✅ Dashboard com KPIs financeiros

## 📋 Pré-requisitos

- Flutter SDK 3.0.0 ou superior
- Conta no Supabase
- Projeto Supabase configurado com as tabelas e RLS

## 🔧 Configuração

### 1. Configurar Supabase

1. Crie um projeto no [Supabase](https://supabase.com)
2. Execute o SQL fornecido no plano para criar as tabelas
3. Configure as políticas RLS (Row Level Security) conforme especificado
4. Copie a URL e a chave anônima do projeto

### 2. Configurar o App Flutter

1. Clone o repositório
2. Abra `lib/core/config/supabase_config.dart`
3. Substitua `YOUR_SUPABASE_URL` e `YOUR_SUPABASE_ANON_KEY` pelas credenciais do seu projeto

```dart
await Supabase.initialize(
  url: 'https://seu-projeto.supabase.co',
  anonKey: 'sua-chave-anon-key',
);
```

### 3. Instalar Dependências

```bash
flutter pub get
```

### 4. Executar o App

```bash
flutter run
```

## 📱 Estrutura do Projeto

```
lib/
├── core/              # Configurações e utilitários
├── data/              # Modelos e repositórios
├── domain/            # Entidades (se necessário)
└── presentation/      # Telas, widgets e providers
    ├── auth/          # Autenticação
    ├── dashboard/     # Dashboard principal
    ├── items/          # Gestão de itens
    ├── customers/      # Gestão de clientes
    ├── orders/         # Gestão de pedidos
    ├── accounts/       # Contas a pagar/receber
    └── shared/         # Componentes compartilhados
```

## 🗄️ Banco de Dados

O sistema utiliza as seguintes tabelas principais:

- `companies` - Empresas
- `profiles` - Perfis de usuários
- `items` - Produtos/Serviços
- `customers` - Clientes
- `orders` - Pedidos
- `order_items` - Itens dos pedidos
- `accounts_receivable` - Contas a receber
- `accounts_payable` - Contas a pagar

## 🔐 Segurança

O sistema utiliza Row-Level Security (RLS) do Supabase para garantir que cada empresa só acesse seus próprios dados. Certifique-se de configurar as políticas RLS corretamente.

## 📝 Notas Importantes

- O sistema é multi-tenant: cada empresa tem seus dados isolados
- Pedidos geram contas a receber automaticamente
- Pedidos cancelados não são excluídos, apenas marcados com flag
- Contas pagas não podem ter valor editado no MVP

## 🧪 Testes

Execute os testes manuais sugeridos:

1. Criar conta e empresa
2. Fazer login
3. Cadastrar itens
4. Cadastrar clientes
5. Criar pedido (verificar geração de contas)
6. Marcar pagamento
7. Criar contas a pagar
8. Verificar isolamento multi-tenant

## 📄 Licença

Este projeto é um MVP desenvolvido para gestão de pequenos negócios.


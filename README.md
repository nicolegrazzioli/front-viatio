# Viatio - Gestor de Gastos Multimoedas (Frontend)

## Sumário

1. [Sobre o Projeto](#1-sobre-o-projeto)
2. [Arquitetura e Fluxo (Offline-First, Flutter + Spring Boot)](#2-arquitetura-e-fluxo-offline-first-flutter--spring-boot)
3. [O que (ainda) não foi implementado ](#3-o-que-ainda-não-foi-implementado)
4. [Como Configurar e Rodar](#4-como-configurar-e-rodar)

---

## 1. Sobre o Projeto

O **Viatio** é um assistente financeiro mobile on/off-line para intercambistas e nômades digitais. Seu principal diferencial é a gestão inteligente do Custo Médio (VET - Valor Efetivo Total).
A ideia central é simples: você registra seus aportes de moeda estrangeira (ex: comprou EUR com BRL) e o app calcula seu custo médio. Quando você cadastra uma despesa na viagem, o app converte automaticamente o valor para Reais usando o _seu_ VET consolidado, e não a cotação comercial do dia, mostrando o impacto real no bolso.

## 2. Arquitetura e Fluxo (Offline-First, Flutter + Spring Boot)

O ecossistema é dividido em um app mobile (Flutter) e uma API REST (Java Spring Boot), utilizando uma arquitetura **Offline-First**.

- **Frontend (Flutter) e Armazenamento Local (Sqflite):**
  - Toda operação de escrita (criar viagem, registrar gasto) é salva **primeiro localmente** no banco de dados interno SQLite (através das classes DAO).
  - O registro é marcado com uma flag de pendência (`is_synced = 0`) e o app tenta enviar a informação para a API via repositório.
  - Caso falhe por falta de conexão, a operação não quebra; o usuário continua usando os dados locais cacheados sem interrupções.
  - Há um serviço (`SyncEngine`) pronto para rodar sincronizações pendentes enviando-as para o servidor em lote. Ao ler dados, o Flutter mescla os dados da nuvem com as suas edições locais pendentes.
- **Backend (Spring Boot + PostgreSQL):** A nuvem serve como a fonte da verdade e backup central. Ela valida os cálculos financeiros de VET e sincroniza os aparelhos de forma centralizada.
- **Autenticação (JWT):** O login consome a API para validar a conta, e o app guarda o token para assinar todas as tentativas futuras de sincronização.

### 2.1. Estrutura de pastas
```
lib/
 |-- screens/ 
 |-- widgets/ 
 |-- core/ 
       |-- api/
       |-- authentication
       |-- database
       |-- dao
       |-- models
       |-- repositories
       |-- providers
       |-- sync
       |-- theme
       |-- constants
       |-- utils

```
- lib/screens --> as telas/páginas
- lib/widgets --> componentes visuais menores e reutilizáveis (botão, menu)
- lib/core --> lógica e funcionamento
- lib/core/api --> requisições HTTP para o servidor
- lib/core/authenticartion --> estado de login, controle de token e sessão
- lib/core/database --> configura o banco de dados interno do celular (sqlite), cria as tabelas
- lib/core/dao --> queries do banco de dados para interagir com o sqlite, cada tabela tem seu DAO
- lib/core/models --> classes, transformam os objetos do banco de dados em objetos que o Dart entende
- lib/core/repositories --> decide se vai buscar o dado na API online ou no banco de dados local do celular
- lib/core/providers --> gerencia o estado do app, mantém os dados carregados na memória do celular enquanto o usuário usa o app e notifica a tela para atualizar quando um dado muda (ex: adiciona novo gasto)
- lib/core/sync --> lógica do offline-first, tudo que for feito sem internet vai ser enviado ao servidor quando tiver conexão
- lib/core/theme --> cores, fontes e estilos globais
- lib/core/constants e /utils --> constantes globais (ex: URLs de API) e funções gerais (ex: formatador de data)


### 2.2. Fluxo de arquivos
1. **Interface (`screens/` e `widgets/`)**: A tela captura a ação do usuário (ex: toque em salvar despesa)
2. **Estado (`providers/`)**: O widget chama um método do `Provider` correspondente para atualizar a interface 
3. **Regra de Dados (`repositories/`)**: O `Provider` delega a persistência para o `Repository`, que gerencia a integridade local e remota
4. **Armazenamento (`dao/` e `database/`)**: O `Repository` aciona o `DAO` para gravar a alteração no SQLite local 
5. **Comunicação e Sincronização (`api/` e `sync/`)**: O `Repository` envia o dado ao backend através do `ApiClient` e, caso offline, a sincronização é reagendada na `SyncEngine`


### 2.3. Offline first e sincronização
**offline-first**
- quando clica em salvar, o app grava o novo dado no banco de dados local do celular (sqlite) e atualiza a tela lendo esse banco
- ao mesmo tempo, o app tenta enviar essa atualização para o servidor (postgres)

**status de sincronização**

- cada tabela do banco de dados possui um campo `was_synced`(true ou false)
- ao criar algo offline, o dado é salvo localmente com `was_synced = false`
- quando tiver internet, o celular envia o dado para a nuvem e atualiza o registro para `was_synced = true`

**fluxo de sincronização**
- executada pelo SyncService
- *enviar* - o app faz uma busca no banco local de tudo que tem `was_synced = false` e envia essa lista de dados para a API do servidor por requisições HTTP - se der certo o status muda para true, se falhar (ex: celular no modo avião) continua false
- *receber* - o app pede ao servidor os dados alterados na nuvem desde a última sincronização, e salva esses dados no banco local, assim alterações feitas em outros dispositivos aparecem

*quando é sincronizado*
- abertura do app (initSession)
- mudança de conexão ou ações do usuário (ex: cadastrar um gasto estando online)
- puxar para atualizar (arrasta a tela para baixo para atualizar manualmente)

### 2.4. Cálculo do VET do dia selecionado
- pega a data selecionada no calendário do gasto e busca no banco de dados (sqlite) compras daquela moeda apenas até essa data (<=)
- calcula a média: reais gastos ate a data / total da moeda adquirido até a data
- o VET calculado é gravado no registro do gasto do banco local e não muda


## 3. O que (ainda) não foi implementado

Por se tratar de um **MVP** (Produto Mínimo Viável), o foco do desenvolvimento foi garantir a solidez das regras financeiras off/on-line. 

- **Upload de Imagens (Foto de Perfil e Comprovantes):** O banco de dados (nuvem e local) já prevê as colunas `profile_image` e `photo_path`. Porém, a UI e a lógica de envio no Flutter não foram feitas. Motivo: pedir permissões de galeria/câmera, gerenciar arquivos pesados no cache local offline, e sincronizar blobs para nuvem (AWS S3) adicionaria muito risco e esforço.
- **Página Detalhada do Usuário:** A prioridade é a tela de viagens. A gestão de conta (trocar e-mail, senha) ficará para versões posteriores.
- **Login com Google (Próximo Passo):** Em vez de manter o login/cadastro com e-mail/senha, a transição para Login Único com Google simplificará o sistema (removendo telas de cadastro, recuperação de senha, etc.) e elevará o nível de segurança, eliminando a necessidade de gerenciar ou armazenar senhas na nuvem ou no SQLite local.

## 4. Como Configurar e Rodar

### Pré-requisitos

- Flutter SDK devidamente instalado.
- Backend rodando localmente (porta `8081`).
- **IP:** Se for rodar no celular físico ou emulador Android, a URL base da API no código Flutter não pode ser `localhost` (pois o localhost do celular aponta para ele mesmo). Você precisará usar o IPv4 da sua máquina na rede Wi-Fi (ex: `http://192.168.1.x:8081`).

### Rodando no Navegador (Web/Chrome)

```bash
flutter run -d chrome
```

### Rodando no Celular Físico

Para testes do banco SQLite local:

1. Conecte o cabo USB no computador e no celular.
2. No celular, ative o **Modo Desenvolvedor**: Vá em `Configurações > Sobre o Telefone` e toque 7 vezes seguidas em `Número da Versão` (ou Build Number).
3. Volte nas configurações, entre em `Opções de Desenvolvedor` e ative a **Depuração USB** (USB Debugging).
4. Uma pop-up vai aparecer no celular, clique em "Permitir".
5. No terminal (dentro da pasta raiz `front-viatio`), rode:

```bash
flutter run
```

### Gerando o APK (para instalação direta)

```bash
flutter build apk --release -t lib/main.dart --dart-define=API_URL=http://192.168.0.000:8081
```

O arquivo APK gerado estará disponível no caminho:
`build/app/outputs/flutter-apk/app-release.apk`

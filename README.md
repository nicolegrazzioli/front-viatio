# Viatio - Gestor de Gastos Multimoedas (Frontend)

## Sumário
1. [Sobre o Projeto](#1-sobre-o-projeto)
2. [Arquitetura e Fluxo (Offline-First, Flutter + Spring Boot)](#2-arquitetura-e-fluxo-offline-first-flutter--spring-boot)
3. [O que (ainda) não foi implementado e por quê](#3-o-que-ainda-não-foi-implementado-e-por-quê)
4. [Como Configurar e Rodar](#4-como-configurar-e-rodar)

---

## 1. Sobre o Projeto
O **Viatio** é um assistente financeiro mobile focado em viajantes, intercambistas e nômades digitais. Seu principal diferencial é a gestão inteligente do Custo Médio (VET - Valor Efetivo Total). 
A ideia central é simples: você registra seus aportes de moeda estrangeira (ex: comprou EUR com BRL) e o app calcula seu custo médio. Quando você cadastra uma despesa na viagem, o app converte automaticamente o valor para Reais usando o *seu* VET consolidado, e não a cotação comercial do dia, mostrando o impacto real no bolso.

## 2. Arquitetura e Fluxo (Offline-First, Flutter + Spring Boot)
O ecossistema é dividido em um app mobile (Flutter) e uma API REST (Java Spring Boot), utilizando uma arquitetura **Offline-First**.

- **Frontend (Flutter) e Armazenamento Local (Sqflite):** 
  - Toda operação de escrita (criar viagem, registrar gasto) é salva **primeiro localmente** no banco de dados interno SQLite (através das classes DAO).
  - O registro é marcado com uma flag de pendência (`is_synced = 0`) e o app tenta enviar a informação para a API via repositório.
  - Caso falhe por falta de conexão, a operação não quebra; o usuário continua usando os dados locais cacheados sem interrupções.
  - Há um serviço (`SyncEngine`) pronto para rodar sincronizações pendentes enviando-as para o servidor em lote. Ao ler dados, o Flutter mescla os dados da nuvem com as suas edições locais pendentes.
- **Backend (Spring Boot + PostgreSQL):** A nuvem serve como a fonte da verdade e backup central. Ela valida os cálculos financeiros de VET e sincroniza os aparelhos de forma centralizada.
- **Autenticação (JWT):** O login consome a API para validar a conta, e o app guarda o token para assinar todas as tentativas futuras de sincronização.

## 3. O que (ainda) não foi implementado e por quê
Por se tratar de um **MVP** (Produto Mínimo Viável), o foco do desenvolvimento foi garantir a solidez das regras financeiras off/on-line. Algumas features de apoio não entraram:

- **Upload de Imagens (Foto de Perfil e Comprovantes):** O banco de dados (nuvem e local) já prevê as colunas `profile_image` e `photo_path`. Porém, a UI e a lógica de envio no Flutter não foram feitas. Motivo: pedir permissões de galeria/câmera, gerenciar arquivos pesados no cache local offline, e sincronizar blobs para nuvem (AWS S3) adicionaria muito risco e esforço.
- **Página Detalhada do Usuário:** A prioridade é a tela de viagens. A gestão de conta (trocar e-mail, senha) ficará para versões posteriores.

## 4. Como Configurar e Rodar

### Pré-requisitos
- Flutter SDK devidamente instalado.
- Backend rodando localmente (porta `8081`).
- **Atenção ao IP:** Se for rodar no celular físico ou emulador Android, a URL base da API no código Flutter **não pode** ser `localhost` (pois o localhost do celular aponta para ele mesmo). Você precisará usar o IPv4 da sua máquina na rede Wi-Fi (ex: `http://192.168.1.x:8081`).

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
Para gerar o arquivo APK de produção e instalar diretamente no dispositivo Android, execute o seguinte comando na raiz do projeto:
```bash
flutter build apk --release
```
O arquivo APK gerado estará disponível no caminho:
`build/app/outputs/flutter-apk/app-release.apk`



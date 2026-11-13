# ICEIBank

Sistema bancário simplificado, desenvolvido para a disciplina de Laboratório de
Desenvolvimento de Aplicações Móveis e Distribuídas (PUC Minas).

O banco é dividido em agências: cada agência é uma partição independente de
contas (`id_conta % número_de_agências`). O projeto evolui em 4 sprints, cada
uma aplicando um conceito de Sistemas Distribuídos diferente. **Este
repositório está no Sprint 3**: as agências elegem uma líder entre si
(algoritmo de Bully com heartbeat e failover automático) e nasce o app Flutter,
offline-first, que usa o relógio vetorial do Sprint 2 para detectar conflito ao
sincronizar operações feitas sem conexão.

## Stack

- **Backend:** Java 21 + Spring Boot 3.5 (Maven)
- **Mensageria:** RabbitMQ (Spring AMQP), via CloudAMQP ou Docker local
- **Frontend:** React + TypeScript (Vite)
- **Mobile:** Flutter (http, shared_preferences, Hive, connectivity_plus)
- **Autenticação:** JWT (jjwt)

## RabbitMQ

A agência **não sobe** sem a variável de ambiente `RABBITMQ_URL` (ela contém
usuário e senha do broker, por isso nunca vai para o repositório).

- **CloudAMQP:** crie uma instância (plano Little Lemur, gratuito) e copie a
  AMQP URL (`amqps://usuario:senha@host.cloudamqp.com/vhost`).
- **Alternativa local (Docker):**

  ```bash
  docker run -d --name rabbitmq-iceibank -p 5672:5672 -p 15672:15672 rabbitmq:3-management
  ```

  Nesse caso `RABBITMQ_URL=amqp://localhost` e o RabbitMQ Manager fica em
  `http://localhost:15672` (usuário/senha `guest`/`guest`).

Topologia criada pelas agências ao subir:

| Elemento | Nome | Observação |
|---|---|---|
| Exchange (topic, durável) | `iceibank.eventos` | |
| Fila (durável) | `fila-agencia-{0,1,2}` | cada agência declara e consome a sua |
| Binding | `agencia.<id>.creditar` → `fila-agencia-<id>` | |
| Fila (durável) | `fila-auditoria` | funcionalidade adicional, binding `agencia.#` |

## Como rodar o backend

Cada agência é o mesmo código, identificada por `--iceibank.id` (0, 1 ou 2).
A porta é calculada automaticamente a partir do id. Em **cada** terminal:

```bash
export RABBITMQ_URL="amqps://..."          # PowerShell: $env:RABBITMQ_URL="amqps://..."
cd agencia
mvn spring-boot:run -Dspring-boot.run.arguments="--iceibank.id=0"   # porta 4000
mvn spring-boot:run -Dspring-boot.run.arguments="--iceibank.id=1"   # porta 4001
mvn spring-boot:run -Dspring-boot.run.arguments="--iceibank.id=2"   # porta 4002
```

## Como rodar o frontend

```bash
cd frontend
npm install
npm run dev
```

Acesse `http://localhost:5173`. A tela permite escolher qual agência é a
"porta de entrada" (URL base).

## Login

Credencial fixa (não há modelo de usuário):

- **usuário:** `admin`
- **senha:** `admin123`

## Principais endpoints

Todas as rotas abaixo, exceto `/auth/login` e `/health`, exigem
`Authorization: Bearer <token>`.

| Método | Rota | Descrição |
|---|---|---|
| POST | `/auth/login` | Login, retorna token JWT |
| POST | `/contas` | Cria conta |
| GET | `/contas/{id}` | Consulta saldo |
| POST | `/contas/{id}/depositar` | Depósito |
| POST | `/contas/{id}/sacar` | Saque |
| POST | `/transferencias` | Transferência (local ou entre agências) |
| POST | `/contas/{id}/sincronizar` | Aplica operação feita offline pelo app (409 se o vetor mudou) |
| GET | `/health` | Health-check público (id da agência + status) |
| GET | `/status` | Health-check protegido (relógio vetorial + total de contas) |

`GET /contas/{id}` também devolve `vetorAtual` (relógio vetorial da agência no
momento da leitura), que o app guarda para sincronizar depois.

Rotas do Bully (públicas, chamadas entre as agências e pelo app):

| Método | Rota | Descrição |
|---|---|---|
| POST | `/bully/eleicao` | Recebe `{origemId, vetorEnvio}`; o 200 é o "OK" e a agência inicia a própria eleição |
| POST | `/bully/coordenador` | Recebe `{liderId, vetorEnvio}` e passa a reconhecer essa líder |
| GET | `/bully/lider` | `{idAgencia, liderAtual}` (`liderAtual` null = eleição em andamento) |

A rota `/contas/{id}/creditar-remoto` do Sprint 1 foi removida: o crédito
entre agências agora chega pela fila.

## Transferência entre agências (Sprint 2)

1. A agência de origem debita a conta (evento local no relógio vetorial).
2. Incrementa o relógio (`aoEnviar`) e publica `CreditoRemotoMessage`
   (`idConta`, `valor`, `vetorEnvio`, `origemAgencia`) na exchange
   `iceibank.eventos`, com routing key `agencia.<destino>.creditar`.
3. Responde **200 = mensagem publicada** (não "crédito aplicado").
4. A agência de destino consome da sua fila, aplica `aoReceber(vetorEnvio)` e
   credita a conta (`TRANSFERENCIA_CREDITO_REMOTO`) ou, se a conta não
   existir, registra `CREDITO_REMOTO_FALHOU`.

Se a agência de destino estiver fora do ar, a mensagem fica retida na fila
dela (durável, mensagem persistente) e é entregue quando ela voltar.

## Linha do tempo unificada

Depois de gerar eventos com as agências, para mesclar os
`data/eventos-agencia-*.jsonl` numa linha do tempo e listar os pares de
eventos **causais** e **concorrentes** entre agências (comparando os relógios
vetoriais):

```bash
cd agencia
mvn spring-boot:run -Dspring-boot.run.main-class=br.pucminas.iceibank.agencia.MesclarLogs
```

## Eleição de líder (Sprint 3)

Ao subir, cada agência inicia uma eleição (Bully): pergunta às agências de id
maior; se nenhuma responder em 1s ela vira líder e anuncia a todas. A cada 3s
o heartbeat consulta `/bully/lider` na líder; se ela não responder, a agência
registra `LIDER_NAO_RESPONDEU` e inicia nova eleição. A líder ainda é só
informativa (vai coordenar o 2PC no Sprint 4).

Funcionalidade adicional: os dois tempos são configuráveis por variável de
ambiente (o terminal mostra `[Bully] timeout=...ms, heartbeat=...ms` ao subir):

```bash
export BULLY_HEARTBEAT_MS=1000   # padrao 3000
export BULLY_TIMEOUT_MS=500      # padrao 1000
```

Histórico de lideranças a partir dos logs das 3 agências:

```bash
cd agencia
mvn spring-boot:run -Dspring-boot.run.main-class=br.pucminas.iceibank.agencia.HistoricoLideranca
```

## App mobile (Sprint 3)

```bash
cd app_mobile
flutter pub get
flutter run            # com um emulador Android (ou simulador iOS) aberto
```

Login `admin`/`admin123`. O campo "Host das agências" vem com `10.0.2.2` no
emulador Android (o `localhost` do computador) e `localhost` no simulador iOS;
a agência N responde na porta 4000 + N e cada conta é consultada na agência
`id % 3`.

- **Painel de liderança:** consulta `/bully/lider` a cada 3s, tentando as
  outras agências se a consultada não responder.
- **Offline-first:** saldo e `vetorAtual` de cada conta consultada ficam em
  cache (Hive). Depósito/saque sem conexão vai para uma fila de pendentes, com
  saldo provisório na tela, e é sincronizado sozinho (`/sincronizar`) quando a
  conexão volta. Em conflito (409) a operação fica marcada e o app mostra o
  saldo real com as opções Descartar e Reenviar.

## Limitações conhecidas

- **Débito sem compensação:** se o crédito falhar no destino
  (`CREDITO_REMOTO_FALHOU`) ou a publicação no broker falhar, o débito já
  aplicado na origem não é revertido, e a origem nem fica sabendo da falha no
  destino. É o problema que o Sprint 4 (2PC/Saga) resolve.
- **Estado em memória:** contas e relógio vetorial vivem em memória. Ao
  reiniciar, a agência perde as contas e o vetor volta para zero.
- **Conflito por agência, não por conta:** qualquer evento da agência (até de
  outra conta ou das mensagens do Bully) muda o vetor, então a sincronização
  offline pode recusar uma operação que não tinha conflito real.
- **Testes gravam em `data/`:** o `mvn test` sobe a aplicação, que já inicia
  uma eleição e grava eventos em `data/eventos-agencia-0.jsonl`.

## Documentação do sprint

- Respostas e justificativas de design: [`RESPOSTAS.md`](RESPOSTAS.md)
- Evidências de teste: [`evidencias/sprint1/`](evidencias/sprint1),
  [`evidencias/sprint2/`](evidencias/sprint2) e
  [`evidencias/sprint3/`](evidencias/sprint3)

## Nota de transparência: uso de IA

Assim como previsto no roteiro, ferramentas de IA foram utilizadas neste
sprint, de forma responsável, para apoiar a revisão de código, geração de
alguns arquivos e documentação. Quando a IA foi usada para criar código diretamente, o
arquivo correspondente traz um comentário declarando esse uso. 

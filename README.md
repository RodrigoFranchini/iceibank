# ICEIBank

Sistema bancário simplificado, desenvolvido para a disciplina de Laboratório de
Desenvolvimento de Aplicações Móveis e Distribuídas (PUC Minas).

O banco é dividido em agências: cada agência é uma partição independente de
contas (`id_conta % número_de_agências`). O projeto evolui em 4 sprints, cada
uma aplicando um conceito de Sistemas Distribuídos diferente. **Este
repositório está no Sprint 1** (API REST/MVC + relógio lógico de Lamport).

## Stack

- **Backend:** Java 21 + Spring Boot 3.5 (Maven)
- **Frontend:** React + TypeScript (Vite)
- **Autenticação:** JWT (jjwt)

## Como rodar o backend

Cada agência é o mesmo código, identificada por `--iceibank.id` (0, 1 ou 2).
A porta é calculada automaticamente a partir do id.

```bash
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

Credencial fixa para este sprint (não há modelo de usuário):

- **usuário:** `admin`
- **senha:** `admin123`

## Principais endpoints

Todas as rotas abaixo, exceto `/auth/login`, `/health` e `/contas/{id}/creditar-remoto`,
exigem `Authorization: Bearer <token>`.

| Método | Rota | Descrição |
|---|---|---|
| POST | `/auth/login` | Login, retorna token JWT |
| POST | `/contas` | Cria conta |
| GET | `/contas/{id}` | Consulta saldo |
| POST | `/contas/{id}/depositar` | Depósito |
| POST | `/contas/{id}/sacar` | Saque |
| POST | `/transferencias` | Transferência (local ou entre agências) |
| POST | `/contas/{id}/creditar-remoto` | Uso interno, chamado por outra agência |
| GET | `/health` | Health-check público (id da agência + status) |
| GET | `/status` | Health-check protegido (relógio de Lamport + total de contas) |

## Linha do tempo unificada

Depois de gerar eventos com as agências, para observar o relógio de Lamport
em ação, mesclando os `.jsonl` de todas as agências numa única linha do tempo
ordenada por timestamp:

```bash
mvn spring-boot:run -Dspring-boot.run.main-class=br.pucminas.iceibank.agencia.MesclarLogs
```

## Limitação conhecida (Sprint 1)

Se uma transferência entre agências falhar no meio do caminho (agência de
destino fora do ar), o débito já aplicado na origem não é revertido
automaticamente — o dinheiro "some" temporariamente. Isso é intencional: é o
problema que o Sprint 4 (transações distribuídas, 2PC/Saga) resolve de
verdade. Por enquanto, o sistema apenas registra a inconsistência no log de
eventos.

## Documentação do sprint

- Respostas e justificativas de design: [`RESPOSTAS.md`](RESPOSTAS.md)
- Evidências de teste: [`evidencias/sprint1/`](evidencias/sprint1)

## Nota de transparência: uso de IA

Assim como previsto no roteiro, ferramentas de IA foram utilizadas neste
sprint, de forma responsável, para apoiar a revisão de código e a geração de
alguns arquivos. Quando a IA foi usada para criar código diretamente, o
arquivo correspondente traz um comentário declarando esse uso. 

# Respostas 

### Parte B

1. O relógio utiliza de max(contador_local, timestampRecebido) + 1, pois a função evita que o relógio tenha retrocesso, o + 1 garante incremento somente depois do envio.
2. O valor da agência com maior número de eventos é refletido para as agências com número menor.


### Parte D

1. O relógio local só precisa de chamar a função eventoLocal() que já garante a ordem. Entre agências, cada um tem relógio próprio e precisa escutar o relógio das demais para registrar o timestamp da operação.
2. Não, isso quebra o esperado de uma transação bancária, o dinheiro some do sistema.
3. A agência só garantir a operação quando ela foi validada nas demais ou estorno pro cliente se a operação não concluir.

### 10.2 Parte 3

- Concorrentes, não há comunicação entre as agências direta. A ordem do campo horaParede não bate com Lamport que seria 0 -> 1 -> 2, mas aparece 1 primeiro.

### Parte E

1. ?
2. Não é suficiente, Lamport não distingue A concorrente de B ou A antes de B quando os timestamp diferem.

### Parte F

1. Autenticação responde quem é o usuário no sistema. Autorização da acesso ao usuário no sistema. Um usuário com um token de outro usuário consegue acesso em um sistema sem autorização, pois não existe sistema de dono da conta.
2. O sistema fica mais escalável sem ter que validar toda requisição com uma busca no banco de dados, podendo consultar a chave secreta sem precisar consultar nenhum outro registro.
3. Qualquer pessoa consegue forjar o token e acessar a agência.

### Parte G

1. Salva no localStorage do browser.
2. O usuário ve a mensagem de token expirado.
3. Model é a conta, View o jsx etornado e Controller é as funções. Porém não há separação em camadas

---

# Sprint 2

### 6.4

1. Com 10 agências o vetor passa a ter 10 posições, uma para cada agência. Ele cresce com o número de agências e não com o número de eventos, mas toda mensagem e toda linha do log carregam o vetor inteiro.
2. [3,1,0] aconteceu antes de [3,2,0], todas as posições do primeiro são menores ou iguais às do segundo. No teste o crédito na agência 1 ficou [3,2,0] depois de receber [3,0,0] da agência 0.
3. São concorrentes, cada um é maior em uma posição (3 > 1 na primeira e 3 > 1 na segunda), então um não sabia do outro. Com Lamport não dá para ver isso.

### 7.5

1. Com a agência 1 fora a transferência respondeu 200 e a mensagem ficou guardada na fila-agencia-1. Quando a agência 1 voltou ela consumiu a mensagem na hora, mas a conta 4 não existia mais porque fica em memória, então deu CREDITO_REMOTO_FALHOU. A conta 3 ficou com 50, o dinheiro some do sistema igual no Sprint 1.
2. Melhorou que a origem não precisa que o destino esteja no ar e nem saber a porta dele, só a routing key, e a mensagem não se perde. Continua sem confirmação do crédito para a origem, sem estorno quando o crédito falha e o RabbitMQ virou um ponto único de falha.
3. Em parte não, o listener não é uma rota HTTP e para publicar na fila precisa do usuário e senha do RabbitMQ. Mas quem tiver a RABBITMQ_URL consegue publicar um crédito falso, as 3 agências usam a mesma credencial e a mensagem não é assinada.

### 8.3

1. Comparar o vetor posição por posição. Se cada um é maior em pelo menos uma posição nenhum evento sabia do outro, então são concorrentes.
2. agencia-0 CRIAR_CONTA [1,0,0] || agencia-2 CRIAR_CONTA [0,0,1], as contas foram criadas ao mesmo tempo sem comunicação entre as agências 0 e 2. Já o débito [2,0,0] e o crédito [3,2,0] aparecem como causais e não como concorrentes.
3. Comparar todos os pares é O(n²), com 10 eventos são 45 pares e com 10 mil são uns 50 milhões. Serve para poucos logs, para escalar teria que comparar só eventos da mesma conta ou de um intervalo de tempo.

### Funcionalidade adicional

Fila de auditoria. A fila-auditoria está ligada na exchange com o binding agencia.#, então recebe uma cópia de toda mensagem entre agências. As 3 agências consomem a mesma fila e quem pegar a mensagem grava no data/auditoria.jsonl. Escolhi por ser a mais simples e mostrar o topic exchange mandando a mesma mensagem para duas filas sem mudar quem publica. Para testar é só fazer transferências entre agências diferentes e olhar o data/auditoria.jsonl e a fila-auditoria no RabbitMQ Manager com 3 consumidores.

---

# Sprint 3

### 5.5

1. O maior ID é só uma regra que todas as agências conhecem, assim ninguém precisa negociar quem vence. Se fosse o menor também funcionaria, só mudaria a líder (a agência 0), o importante é todas usarem a mesma regra.
2. É esperado. Na subida as agências ainda não se enxergam e cada eleição recebida faz a agência iniciar a própria eleição, então o TORNOU_LIDER aparece mais de uma vez. No teste a agência 2 apareceu 4 vezes como TORNOU_LIDER e no fim as 3 responderam liderAtual 2.
3. Para este projeto não, roda em localhost e a líder ainda é só informativa. Em um sistema real sim, qualquer um poderia ficar disparando eleições ou mandar um coordenador falso e virar líder, e no Sprint 4 a líder vai coordenar as transações.

### 6.4

1. Com 100ms a queda é detectada quase na hora, mas são 10 requisições por segundo por agência e uma resposta um pouco lenta já vira eleição. Com 60s quase não usa rede, mas o sistema pode ficar até 1 minuto com uma líder fora do ar sem perceber.
2. Não é desejável. A líder pode estar no meio de uma operação, como coordenar uma transação no Sprint 4, e a troca deixa a operação pela metade. Seria melhor a agência que voltou aceitar a líder atual.
3. A agência acha que a líder caiu sem ela ter caído, esquece a líder e começa outra eleição. Pode ficar trocando de líder sem necessidade ou ter duas agências se achando líder até a próxima rodada.

### 7.3

1. Na subida apareceram 4 TORNOU_LIDER, todos da agência 2, então a liderança não trocou de mãos, mas foi anunciada 4 vezes. O resultado é o mesmo, mas custa mensagens a mais na rede, eventos a mais no log e no vetor, e alguns instantes sem líder definida.

### 8.3

1. O app consulta a cada 3 segundos, o mesmo tempo do heartbeat das agências. Consultar mais rápido não adianta porque as agências demoram esse tempo para perceber a queda, e só gastaria bateria e rede do celular.
2. O app mostra o que a agência que respondeu falou, então pode mostrar a líder antiga por alguns segundos. Não é um problema, na próxima consulta já corrige, e a líder ainda é só informativa.
3. Foi reaproveitado a mesma API, o login com JWT, guardar o token e mostrar o erro que a API devolve. No mobile precisou pensar em ficar sem conexão, guardar os dados no aparelho, fila de operações pendentes e mandar cada conta para a agência dona dela (id % 3), no web era uma URL só.

### 9.6

1. O saldo pode voltar ao mesmo valor, um depósito de 50 e um saque de 50 por exemplo, e parecer que nada mudou. O vetor sempre aumenta a cada evento, então mostra que aconteceu alguma coisa mesmo com o saldo igual.
2. O vetor é da agência e não da conta, qualquer evento aumenta ele, até de outra conta ou das mensagens do Bully. É mais simples porque o vetor já existia. Para ser por conta teria que guardar uma versão em cada conta e comparar só ela.
3. Perguntar ao usuário. Descartar sozinho perde a operação sem ele saber e reenviar sozinho pode sacar de um saldo que já mudou. No app a operação fica como conflito, mostra o saldo real e os botões Descartar e Reenviar.

### 10.3

1. Hive, porque é simples e guarda um Map direto sem precisar de SQL. Considerei o sqflite, que precisa criar tabela, e o shared_preferences, que só guarda valores simples e já é usado para o token.
2. A operação ficou vermelha na lista de pendentes como conflito, com a mensagem de que a conta mudou enquanto o app estava offline e o saldo real, e o saldo da tela foi atualizado com o valor da agência. Escolhi deixar o usuário decidir entre Descartar e Reenviar, porque num banco reaplicar sozinho pode deixar a conta negativa.
3. O usuário pode achar que o dinheiro já entrou ou saiu e depois a operação ser recusada, por exemplo sacar contando com um depósito que ainda não foi aplicado. O app mostra o saldo provisório separado com o aviso de pendente e não deixa sacar offline mais que o saldo provisório.

### Funcionalidade adicional

Timeout configurável. O intervalo do heartbeat e o timeout das chamadas do Bully saem do código e vêm das variáveis de ambiente BULLY_HEARTBEAT_MS e BULLY_TIMEOUT_MS (padrão 3000 e 1000, igual ao roteiro). Escolhi por ser a mais simples e ajudar a ver o trade-off da pergunta 6.4. Para testar é só subir as agências com BULLY_HEARTBEAT_MS=1000 e BULLY_TIMEOUT_MS=500, conferir a linha [Bully] timeout=500ms, heartbeat=1000ms no terminal e derrubar a líder, a nova líder aparece mais rápido.

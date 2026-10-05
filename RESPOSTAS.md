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

### Uso de IA

Foi usada IA (Claude) para gerar parte do código, rodar os testes com RabbitMQ local e ajudar nas respostas. Os arquivos criados pela IA têm um comentário avisando. Revisei e testei tudo.

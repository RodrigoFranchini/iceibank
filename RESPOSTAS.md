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


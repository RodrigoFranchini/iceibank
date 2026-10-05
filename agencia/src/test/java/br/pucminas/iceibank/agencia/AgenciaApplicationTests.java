package br.pucminas.iceibank.agencia;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

// No teste nao ha RABBITMQ_URL no ambiente: aponta para um broker local so
// para o contexto subir (a conexao so e aberta quando uma mensagem e enviada).
@SpringBootTest(properties = "spring.rabbitmq.addresses=amqp://localhost")
class AgenciaApplicationTests {

    @Test
    void contextLoads() {
    }
}

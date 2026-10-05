package br.pucminas.iceibank.agencia.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

// Classe criada pela IA para declarar a exchange, as filas e os bindings do RabbitMQ.

/**
 * Topologia do RabbitMQ usada pelas agencias:
 *
 *   Agencia 0 --publish(agencia.1.creditar)--> [exchange topic iceibank.eventos]
 *                                                  | binding agencia.1.creditar
 *                                                  v
 *                                           [fila-agencia-1] --consume--> Agencia 1
 *
 * Cada agencia declara a exchange (idempotente) e a PROPRIA fila. Exchange e
 * fila sao duraveis: sobrevivem a um restart do broker, e a fila continua
 * acumulando mensagens enquanto a agencia dona dela esta fora do ar.
 */
@Configuration
public class AmqpConfig {

    public static final String EXCHANGE = "iceibank.eventos";

    @Bean
    public TopicExchange iceibankEventos() {
        return new TopicExchange(EXCHANGE, true, false);
    }

    @Bean
    public Queue filaDaAgencia(AgenciaProperties agenciaProperties) {
        return new Queue("fila-agencia-" + agenciaProperties.getId(), true);
    }

    @Bean
    public Binding bindingCreditar(AgenciaProperties agenciaProperties) {
        return BindingBuilder.bind(filaDaAgencia(agenciaProperties))
                .to(iceibankEventos())
                .with("agencia." + agenciaProperties.getId() + ".creditar");
    }

    /** Serializa as mensagens como JSON (em vez da serializacao Java padrao). */
    @Bean
    public MessageConverter conversorJson() {
        return new Jackson2JsonMessageConverter();
    }
}

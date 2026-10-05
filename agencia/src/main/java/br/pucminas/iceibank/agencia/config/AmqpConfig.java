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
 *
 * Funcionalidade adicional (Sprint 2): fila-auditoria, ligada com o curinga
 * "agencia.#", recebe uma COPIA de toda mensagem trocada entre agencias.
 */
@Configuration
public class AmqpConfig {

    public static final String EXCHANGE = "iceibank.eventos";
    public static final String FILA_AUDITORIA = "fila-auditoria";

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

    @Bean
    public Queue filaAuditoria() {
        return new Queue(FILA_AUDITORIA, true);
    }

    /** "#" casa com zero ou mais palavras: agencia.0.creditar, agencia.1.creditar, ... */
    @Bean
    public Binding bindingAuditoria() {
        return BindingBuilder.bind(filaAuditoria()).to(iceibankEventos()).with("agencia.#");
    }

    /**
     * Serializa as mensagens como JSON (em vez da serializacao Java padrao).
     * O conversor so aceita desserializar classes do pacote messaging, mesmo
     * quando o tipo vem do cabecalho __TypeId__ (caso do AuditoriaListener,
     * que nao declara um tipo de parametro para o Spring inferir).
     */
    @Bean
    public MessageConverter conversorJson() {
        return new Jackson2JsonMessageConverter("br.pucminas.iceibank.agencia.messaging");
    }
}

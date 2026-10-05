package br.pucminas.iceibank.agencia.messaging;

import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

import br.pucminas.iceibank.agencia.config.AmqpConfig;

// Classe criada pela IA para publicar mensagens na exchange iceibank.eventos.

@Service
public class MensageriaService {

    private final RabbitTemplate rabbitTemplate;

    public MensageriaService(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    /**
     * Publica na exchange iceibank.eventos. O Spring AMQP envia com
     * deliveryMode PERSISTENT por padrao, entao a mensagem e gravada em disco
     * pelo broker (fila duravel + mensagem persistente).
     */
    public void publicar(String routingKey, Object mensagem) {
        rabbitTemplate.convertAndSend(AmqpConfig.EXCHANGE, routingKey, mensagem);
    }
}

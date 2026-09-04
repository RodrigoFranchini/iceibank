package br.pucminas.iceibank.agencia.store;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Component;

import br.pucminas.iceibank.agencia.entities.Conta;

/**
 * Equivalente ao app.locals.contas do roteiro: guarda em memoria as contas
 * desta agencia, compartilhadas entre ContasController e TransferenciasController.
 */
@Component
public class ContaStore {

    private final Map<Integer, Conta> contas = new HashMap<>();

    public Map<Integer, Conta> getContas() {
        return contas;
    }
}

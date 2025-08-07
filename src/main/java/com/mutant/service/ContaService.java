package com.mutant.service;

import com.mutant.dto.ContaResponse;
import com.mutant.dto.TransacaoRequest;
import com.mutant.model.Conta;
import com.mutant.repository.ContaRepository;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class ContaService {

    private final ContaRepository contaRepository;

    public ContaService(ContaRepository contaRepository) {
        this.contaRepository = contaRepository;
    }

    public ContaResponse criarConta() {
        Conta conta = new Conta();
        Conta salva = contaRepository.save(conta);
        return new ContaResponse(salva.getId(), salva.getSaldo());
    }

    public ContaResponse creditar(Long id, TransacaoRequest request) {
        Conta conta = obterConta(id);
        conta.creditar(request.valor());
        return salvarERetornar(conta);
    }

    public ContaResponse debitar(Long id, TransacaoRequest request) {
        Conta conta = obterConta(id);
        conta.debitar(request.valor());
        return salvarERetornar(conta);
    }

    public ContaResponse consultar(Long id) {
        Conta conta = obterConta(id);
        return new ContaResponse(conta.getId(), conta.getSaldo());
    }

    private Conta obterConta(Long id) {
        return contaRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Conta não encontrada"));
    }

    private ContaResponse salvarERetornar(Conta conta) {
        Conta salva = contaRepository.save(conta);
        return new ContaResponse(salva.getId(), salva.getSaldo());
    }
}

package com.mutant.service;

import com.mutant.dto.TransacaoRequest;
import com.mutant.model.Conta;
import com.mutant.repository.ContaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ContaServiceTest {

    private ContaRepository contaRepository;
    private ContaService contaService;

    @BeforeEach
    void setUp() {
        contaRepository = mock(ContaRepository.class);
        contaService = new ContaService(contaRepository);
    }

    @Test
    void deveCriarContaComSaldoZero() {
        Conta conta = new Conta();
        conta.creditar(BigDecimal.ZERO);
        conta.setId(1L);

        when(contaRepository.save(any(Conta.class))).thenReturn(conta);

        var response = contaService.criarConta();

        assertNotNull(response);
        assertEquals(1L, response.id());
        assertEquals(BigDecimal.ZERO, response.saldo());
    }

    @Test
    void deveCreditarValorNaConta() {
        Conta conta = new Conta();
        conta.setId(1L);
        when(contaRepository.findById(1L)).thenReturn(Optional.of(conta));
        when(contaRepository.save(any())).thenReturn(conta);

        var response = contaService.creditar(1L, new TransacaoRequest(new BigDecimal("100.00")));

        assertEquals(new BigDecimal("100.00"), response.saldo());
        verify(contaRepository).save(conta);
    }

    @Test
    void deveDebitarValorNaConta() {
        Conta conta = new Conta();
        conta.setId(1L);
        conta.creditar(new BigDecimal("200"));
        when(contaRepository.findById(1L)).thenReturn(Optional.of(conta));
        when(contaRepository.save(any())).thenReturn(conta);

        var response = contaService.debitar(1L, new TransacaoRequest(new BigDecimal("50.00")));

        assertEquals(new BigDecimal("150.00"), response.saldo());
        verify(contaRepository).save(conta);
    }

    @Test
    void deveConsultarSaldoDaConta() {
        Conta conta = new Conta();
        conta.setId(1L);
        conta.creditar(new BigDecimal("300"));
        when(contaRepository.findById(1L)).thenReturn(Optional.of(conta));

        var response = contaService.consultar(1L);

        assertEquals(1L, response.id());
        assertEquals(new BigDecimal("300"), response.saldo());
    }

    @Test
    void deveLancarExcecaoQuandoContaNaoEncontrada() {
        when(contaRepository.findById(999L)).thenReturn(Optional.empty());

        var ex = assertThrows(IllegalArgumentException.class, () ->
                contaService.consultar(999L));

        assertEquals("Conta não encontrada", ex.getMessage());
    }
}

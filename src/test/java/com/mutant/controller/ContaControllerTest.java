package com.mutant.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mutant.dto.ContaResponse;
import com.mutant.dto.TransacaoRequest;
import com.mutant.service.ContaService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("ContaController Tests")
class ContaControllerTest {

    private MockMvc mockMvc;

    @Mock
    private ContaService contaService;

    @InjectMocks
    private ContaController contaController;

    private ObjectMapper objectMapper;
    private ContaResponse contaResponse;
    private TransacaoRequest transacaoRequest;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(contaController).build();
        objectMapper = new ObjectMapper();

        contaResponse = new ContaResponse(1L, BigDecimal.valueOf(1000.00));
        transacaoRequest = new TransacaoRequest(BigDecimal.valueOf(100.00));
    }

    @Test
    @DisplayName("Deve criar conta com sucesso")
    void deveCriarContaComSucesso() throws Exception {
        when(contaService.criarConta()).thenReturn(contaResponse);

        mockMvc.perform(post("/contas")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(1L))
                .andExpect(jsonPath("$.saldo").value(1000.00));

        verify(contaService, times(1)).criarConta();
    }

    @Test
    @DisplayName("Deve creditar valor com sucesso")
    void deveCreditarValorComSucesso() throws Exception {
        Long contaId = 1L;
        ContaResponse contaAtualizada = new ContaResponse(contaId, BigDecimal.valueOf(1100.00));

        when(contaService.creditar(eq(contaId), any(TransacaoRequest.class)))
                .thenReturn(contaAtualizada);

        mockMvc.perform(post("/contas/{id}/credito", contaId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(transacaoRequest)))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(contaId))
                .andExpect(jsonPath("$.saldo").value(1100.00));

        verify(contaService, times(1)).creditar(eq(contaId), any(TransacaoRequest.class));
    }

    @Test
    @DisplayName("Deve consultar conta com sucesso")
    void deveConsultarContaComSucesso() throws Exception {
        Long contaId = 1L;
        when(contaService.consultar(contaId)).thenReturn(contaResponse);

        mockMvc.perform(get("/contas/{id}", contaId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.id").value(1L))
                .andExpect(jsonPath("$.saldo").value(1000.00));

        verify(contaService, times(1)).consultar(contaId);
    }
}
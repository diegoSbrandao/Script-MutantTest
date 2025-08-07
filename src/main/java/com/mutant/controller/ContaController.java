package com.mutant.controller;

import com.mutant.dto.ContaResponse;
import com.mutant.dto.TransacaoRequest;
import com.mutant.service.ContaService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/contas")
public class ContaController {

    private final ContaService contaService;

    public ContaController(ContaService contaService) {
        this.contaService = contaService;
    }

    @PostMapping
    public ResponseEntity<ContaResponse> criarConta() {
        return ResponseEntity.ok(contaService.criarConta());
    }

    @PostMapping("/{id}/credito")
    public ResponseEntity<ContaResponse> creditar(@PathVariable Long id, @RequestBody TransacaoRequest request) {
        return ResponseEntity.ok(contaService.creditar(id, request));
    }

    @PostMapping("/{id}/debito")
    public ResponseEntity<ContaResponse> debitar(@PathVariable Long id, @RequestBody TransacaoRequest request) {
        return ResponseEntity.ok(contaService.debitar(id, request));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ContaResponse> consultar(@PathVariable Long id) {
        return ResponseEntity.ok(contaService.consultar(id));
    }
}

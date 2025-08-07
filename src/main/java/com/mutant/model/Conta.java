package com.mutant.model;

import jakarta.persistence.*;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
public class Conta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private BigDecimal saldo;

    public Conta() {
        this.saldo = BigDecimal.ZERO;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getId() {
        return id;
    }

    public BigDecimal getSaldo() {
        return saldo;
    }

    public void creditar(BigDecimal valor) {
        this.saldo = saldo.add(valor);
    }

    public void debitar(BigDecimal valor) {
        if (saldo.compareTo(valor) < 0) {
            throw new IllegalArgumentException("Saldo insuficiente");
        }
        this.saldo = saldo.subtract(valor);
    }

}

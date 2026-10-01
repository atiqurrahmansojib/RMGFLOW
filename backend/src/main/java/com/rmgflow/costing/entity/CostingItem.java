package com.rmgflow.costing.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/** Document 9.1: total_cost = unit_cost * consumption * (1 + wastage_percent/100), computed server-side only. */
@Entity
@Table(name = "costing_items")
@Getter
@Setter
@NoArgsConstructor
public class CostingItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "costing_id", nullable = false)
    private Costing costing;

    @Enumerated(EnumType.STRING)
    @Column(name = "component_type", nullable = false)
    private CostingComponentType componentType;

    private String description;

    @Column(name = "unit_cost", nullable = false)
    private BigDecimal unitCost;

    @Column(nullable = false)
    private BigDecimal consumption = BigDecimal.ONE;

    @Column(name = "wastage_percent", nullable = false)
    private BigDecimal wastagePercent = BigDecimal.ZERO;

    @Column(name = "total_cost", nullable = false)
    private BigDecimal totalCost;
}

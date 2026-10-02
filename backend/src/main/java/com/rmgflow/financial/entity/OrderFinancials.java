package com.rmgflow.financial.entity;

import com.rmgflow.order.entity.Order;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/** Document 8.8/9.10: operational profitability only — NOT a general ledger (ADR-12).
 * operational_margin_percent is computed at read-time (OrderFinancialsService),
 * never stored, since its formula depends on whether realizedUnitPrice is set yet. */
@Entity
@Table(name = "order_financials")
@Getter
@Setter
@NoArgsConstructor
public class OrderFinancials {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", nullable = false, unique = true)
    private Order order;

    @Column(name = "quoted_unit_price")
    private BigDecimal quotedUnitPrice;

    @Column(name = "actual_cost_unit")
    private BigDecimal actualCostUnit;

    @Column(name = "realized_unit_price")
    private BigDecimal realizedUnitPrice;
}

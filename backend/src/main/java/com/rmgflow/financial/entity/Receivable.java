package com.rmgflow.financial.entity;

import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.masterdata.entity.Currency;
import com.rmgflow.order.entity.Order;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/** Document 9.10: status (PENDING/PARTIAL/RECEIVED/OVERDUE) is always computed at
 * read-time from due_date/received_amount vs amount — never manually set. */
@Entity
@Table(name = "receivables")
@Getter
@Setter
@NoArgsConstructor
public class Receivable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "buyer_id", nullable = false)
    private Buyer buyer;

    @Column(nullable = false)
    private BigDecimal amount;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "currency", nullable = false)
    private Currency currency;

    @Column(name = "due_date", nullable = false)
    private LocalDate dueDate;

    @Column(name = "received_amount", nullable = false)
    private BigDecimal receivedAmount = BigDecimal.ZERO;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}

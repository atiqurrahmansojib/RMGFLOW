package com.rmgflow.production.entity;

import com.rmgflow.identity.entity.User;
import com.rmgflow.order.entity.Order;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;

/** Document 8.8/9.6: one row per order per day — cumulative totals are always a
 * SUM over these rows (ProductionUpdateService), never a stored running total. */
@Entity
@Table(name = "production_updates")
@Getter
@Setter
@NoArgsConstructor
public class ProductionUpdate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @Column(name = "update_date", nullable = false)
    private LocalDate updateDate;

    @Column(name = "cutting_qty", nullable = false)
    private int cuttingQty;

    @Column(name = "sewing_qty", nullable = false)
    private int sewingQty;

    @Column(name = "finishing_qty", nullable = false)
    private int finishingQty;

    @Column(name = "packing_qty", nullable = false)
    private int packingQty;

    @Column(name = "rejection_qty", nullable = false)
    private int rejectionQty;

    @Column(name = "alteration_qty", nullable = false)
    private int alterationQty;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "entered_by")
    private User enteredBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}

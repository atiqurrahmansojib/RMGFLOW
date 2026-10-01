package com.rmgflow.factory.entity;

import com.rmgflow.buyer.entity.Buyer;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

/**
 * Document 9.4 hard rule: a factory not APPROVED for a buyer cannot be assigned to
 * that buyer's order (enforced in OrderService, Phase 6) — this is the data source
 * that check reads.
 */
@Entity
@Table(name = "factory_buyer_approvals", uniqueConstraints = @UniqueConstraint(columnNames = {"factory_id", "buyer_id"}))
@Getter
@Setter
@NoArgsConstructor
public class FactoryBuyerApproval {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "factory_id", nullable = false)
    private Factory factory;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "buyer_id", nullable = false)
    private Buyer buyer;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private FactoryBuyerApprovalStatus status = FactoryBuyerApprovalStatus.PENDING;

    @Column(name = "approved_date")
    private LocalDate approvedDate;

    @Column(name = "expiry_date")
    private LocalDate expiryDate;
}

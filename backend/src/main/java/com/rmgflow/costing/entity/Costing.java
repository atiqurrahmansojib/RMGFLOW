package com.rmgflow.costing.entity;

import com.rmgflow.identity.entity.Organization;
import com.rmgflow.identity.entity.User;
import com.rmgflow.inquiry.entity.Inquiry;
import com.rmgflow.masterdata.entity.Currency;
import com.rmgflow.style.entity.Style;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Document 8.5/9.1/ADR-14: versioned costing, immutable once APPROVED — enforced by
 * a DB trigger (V13 migration) AND the service layer (defense in depth, same
 * pattern as the audit log's append-only grant).
 */
@Entity
@Table(name = "costings")
@Getter
@Setter
@NoArgsConstructor
public class Costing {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "style_id", nullable = false)
    private Style style;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inquiry_id")
    private Inquiry inquiry;

    @Column(name = "version_no", nullable = false)
    private int versionNo;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "currency", nullable = false)
    private Currency currency;

    @Column(name = "exchange_rate", nullable = false)
    private BigDecimal exchangeRate = BigDecimal.ONE;

    @Column(nullable = false)
    private int quantity;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CostingStatus status = CostingStatus.DRAFT;

    @Column(name = "target_price")
    private BigDecimal targetPrice;

    @Column(name = "total_cost", nullable = false)
    private BigDecimal totalCost = BigDecimal.ZERO;

    @Column(name = "margin_percent")
    private BigDecimal marginPercent;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "superseded_from_id")
    private Costing supersededFrom;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    private User createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "approved_at")
    private Instant approvedAt;

    @Version
    @Column(nullable = false)
    private int version;

    @OneToMany(mappedBy = "costing", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CostingItem> items = new ArrayList<>();
}

package com.rmgflow.inquiry.entity;

import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.identity.entity.Organization;
import com.rmgflow.identity.entity.User;
import com.rmgflow.masterdata.entity.Currency;
import com.rmgflow.masterdata.entity.Season;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/** Document 8.3/10.1: inquiry lifecycle (FR-20/21/22/23). */
@Entity
@Table(name = "inquiries")
@Getter
@Setter
@NoArgsConstructor
public class Inquiry {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(name = "inquiry_no", nullable = false, unique = true)
    private String inquiryNo;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "buyer_id", nullable = false)
    private Buyer buyer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "season_id")
    private Season season;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "merchandiser_id")
    private User merchandiser;

    @Column(name = "target_quantity")
    private Integer targetQuantity;

    @Column(name = "target_price")
    private BigDecimal targetPrice;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "target_currency")
    private Currency targetCurrency;

    @Column(name = "delivery_requirement")
    private LocalDate deliveryRequirement;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private InquiryStatus status = InquiryStatus.OPEN;

    @Column(name = "lost_reason")
    private String lostReason;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = Instant.now();
    }
}

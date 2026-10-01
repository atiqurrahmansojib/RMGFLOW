package com.rmgflow.order.entity;

import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.identity.entity.Organization;
import com.rmgflow.masterdata.entity.Country;
import com.rmgflow.masterdata.entity.Currency;
import com.rmgflow.masterdata.entity.Incoterm;
import com.rmgflow.masterdata.entity.PaymentTerm;
import com.rmgflow.quotation.entity.Quotation;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Document 8.6/9.4: the aggregate root T&A/production/quality/shipment (later
 * phases) all hang off. A single buyer PO can map to multiple `Order` rows
 * (one per factory split, FR-71/73) — buyer_po_no is deliberately not unique,
 * only order_no (this system's own internal number) is.
 */
@Entity
@Table(name = "orders")
@Getter
@Setter
@NoArgsConstructor
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(name = "order_no", nullable = false, unique = true)
    private String orderNo;

    @Column(name = "buyer_po_no", nullable = false)
    private String buyerPoNo;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "buyer_id", nullable = false)
    private Buyer buyer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "quotation_id")
    private Quotation quotation;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderStatus status = OrderStatus.CONFIRMED;

    @Column(name = "order_date", nullable = false)
    private LocalDate orderDate;

    @Column(name = "ex_factory_date")
    private LocalDate exFactoryDate;

    @Column(name = "delivery_date")
    private LocalDate deliveryDate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "incoterm")
    private Incoterm incoterm;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payment_terms_id")
    private PaymentTerm paymentTerms;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "destination_country")
    private Country destinationCountry;

    @Column(name = "total_value", nullable = false)
    private BigDecimal totalValue = BigDecimal.ZERO;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "currency", nullable = false)
    private Currency currency;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @Version
    @Column(nullable = false)
    private int version;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = Instant.now();
    }
}

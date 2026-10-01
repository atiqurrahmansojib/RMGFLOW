package com.rmgflow.buyer.entity;

import com.rmgflow.identity.entity.Organization;
import com.rmgflow.masterdata.entity.Country;
import com.rmgflow.masterdata.entity.Currency;
import com.rmgflow.masterdata.entity.Incoterm;
import com.rmgflow.masterdata.entity.PaymentTerm;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/** Document 8.2: buyer master. Immutable-until-approved fields don't apply here — amendments
 * to buyer master data are ordinary edits (unlike costing/quotation/order, Doc 9.1/9.2/9.4). */
@Entity
@Table(name = "buyers")
@Getter
@Setter
@NoArgsConstructor
public class Buyer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(nullable = false, unique = true)
    private String code;

    @Column(nullable = false)
    private String name;

    @Column(name = "group_name")
    private String groupName;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "country")
    private Country country;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "default_currency")
    private Currency defaultCurrency;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "default_payment_terms_id")
    private PaymentTerm defaultPaymentTerms;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "default_incoterm")
    private Incoterm defaultIncoterm;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @Version
    @Column(nullable = false)
    private int version;

    @OneToMany(mappedBy = "buyer", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<BuyerContact> contacts = new ArrayList<>();

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = Instant.now();
    }
}

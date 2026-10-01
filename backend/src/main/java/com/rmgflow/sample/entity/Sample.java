package com.rmgflow.sample.entity;

import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.factory.entity.Factory;
import com.rmgflow.identity.entity.Organization;
import com.rmgflow.style.entity.Style;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "samples")
@Getter
@Setter
@NoArgsConstructor
public class Sample {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(name = "sample_no", nullable = false, unique = true)
    private String sampleNo;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "style_id", nullable = false)
    private Style style;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "buyer_id", nullable = false)
    private Buyer buyer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "factory_id")
    private Factory factory;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "sample_type_id", nullable = false)
    private SampleType sampleType;

    @Column(name = "request_date", nullable = false)
    private LocalDate requestDate;

    @Column(name = "required_date")
    private LocalDate requiredDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "current_status", nullable = false)
    private SampleStatus currentStatus = SampleStatus.REQUESTED;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = Instant.now();
    }
}

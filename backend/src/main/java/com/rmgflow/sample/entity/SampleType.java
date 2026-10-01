package com.rmgflow.sample.entity;

import com.rmgflow.buyer.entity.Buyer;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Document 8.4/9: development/proto/fit/size-set/PP/TOP/shipment, plus buyer-specific types — data-driven, not hardcoded. */
@Entity
@Table(name = "sample_types")
@Getter
@Setter
@NoArgsConstructor
public class SampleType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(name = "is_buyer_specific", nullable = false)
    private boolean buyerSpecific;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "buyer_id")
    private Buyer buyer;
}

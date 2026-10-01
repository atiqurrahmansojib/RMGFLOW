package com.rmgflow.buyer.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "buyer_contacts")
@Getter
@Setter
@NoArgsConstructor
public class BuyerContact {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "buyer_id", nullable = false)
    private Buyer buyer;

    @Column(nullable = false)
    private String name;

    private String department;
    private String email;
    private String phone;

    @Column(name = "is_primary", nullable = false)
    private boolean primary;
}

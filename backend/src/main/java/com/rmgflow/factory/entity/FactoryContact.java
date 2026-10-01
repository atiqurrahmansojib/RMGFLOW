package com.rmgflow.factory.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "factory_contacts")
@Getter
@Setter
@NoArgsConstructor
public class FactoryContact {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "factory_id", nullable = false)
    private Factory factory;

    @Column(nullable = false)
    private String name;

    private String role;
    private String email;
    private String phone;

    @Column(name = "is_primary", nullable = false)
    private boolean primary;
}

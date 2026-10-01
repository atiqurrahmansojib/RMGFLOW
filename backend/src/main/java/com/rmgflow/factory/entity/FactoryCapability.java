package com.rmgflow.factory.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "factory_capabilities", uniqueConstraints = @UniqueConstraint(columnNames = {"factory_id", "product_category"}))
@Getter
@Setter
@NoArgsConstructor
public class FactoryCapability {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "factory_id", nullable = false)
    private Factory factory;

    @Column(name = "product_category", nullable = false)
    private String productCategory;
}

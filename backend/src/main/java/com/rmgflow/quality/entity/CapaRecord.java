package com.rmgflow.quality.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "capa_records")
@Getter
@Setter
@NoArgsConstructor
public class CapaRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "defect_id")
    private Defect defect;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inspection_id")
    private Inspection inspection;

    @Column(nullable = false)
    private String description;

    @Column(name = "corrective_action")
    private String correctiveAction;

    @Column(name = "preventive_action")
    private String preventiveAction;

    @Column(name = "factory_response")
    private String factoryResponse;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CapaStatus status = CapaStatus.OPEN;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "closed_at")
    private Instant closedAt;
}

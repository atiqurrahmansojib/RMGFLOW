package com.rmgflow.identity.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

/**
 * Document 8.1: deliberately polymorphic (scopeType, scopeId) pair rather than two
 * separate FK columns — an assignment is a lightweight access-grant record, not a
 * domain entity in its own right. scopeId existence against buyers/factories is
 * validated in the application layer, not by a DB FK (ADR-08 same trade-off pattern).
 */
@Entity
@Table(name = "assignments", uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "scope_type", "scope_id"}))
@Getter
@Setter
@NoArgsConstructor
public class Assignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "scope_type", nullable = false)
    private ScopeType scopeType;

    @Column(name = "scope_id", nullable = false)
    private Long scopeId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}

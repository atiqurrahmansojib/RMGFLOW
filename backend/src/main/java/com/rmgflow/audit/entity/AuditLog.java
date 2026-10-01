package com.rmgflow.audit.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;

/**
 * Document 8.9/15.7/15.8: append-only audit trail. No service method in this codebase
 * ever updates or deletes a row here — the DB grant (V3 migration) backs that up at
 * the database level too, so a bug here cannot silently tamper with history.
 *
 * previous_value/new_value are stored as pre-serialized JSON text (String), not a
 * JsonNode-typed field — Hibernate 7's JSON type mapper expects a classic
 * com.fasterxml.jackson.databind.JsonNode by default in this Spring Boot 4 /
 * Jackson-3 environment and fails on the new tools.jackson.databind.JsonNode type
 * (see backend/README.md "Notable stack facts"). AuditService does the
 * object-to-JSON-string conversion itself.
 */
@Entity
@Table(name = "audit_logs")
@Getter
@Setter
@NoArgsConstructor
public class AuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id")
    private Long userId;

    @Column(nullable = false)
    private String action;

    @Column(name = "entity_type", nullable = false)
    private String entityType;

    @Column(name = "entity_id")
    private Long entityId;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "previous_value")
    private String previousValue;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "new_value")
    private String newValue;

    private String reason;

    @Column(name = "ip_address")
    private String ipAddress;

    @Column(name = "occurred_at", nullable = false, updatable = false)
    private Instant occurredAt = Instant.now();
}

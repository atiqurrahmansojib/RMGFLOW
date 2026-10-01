package com.rmgflow.style.entity;

import com.rmgflow.identity.entity.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Document 8.3/FR-31/NFR-05: append-only. No service method in this codebase ever
 * UPDATEs a row here after creation — a new spec means a new revision row, never an
 * edit (same immutability discipline as costing/quotation, just without the DB
 * trigger since style data isn't a financial/approval record).
 */
@Entity
@Table(name = "style_revisions")
@Getter
@Setter
@NoArgsConstructor
public class StyleRevision {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "style_id", nullable = false)
    private Style style;

    @Column(name = "revision_no", nullable = false)
    private int revisionNo;

    private String fabric;
    private String composition;
    private BigDecimal gsm;
    private String color;

    @Column(name = "size_range")
    private String sizeRange;

    /** Pre-serialized JSON text, not JsonNode — see AuditLog's javadoc for why. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "measurement_spec")
    private String measurementSpec;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    private User createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}

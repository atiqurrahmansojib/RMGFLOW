package com.rmgflow.buyer.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "buyer_requirements")
@Getter
@Setter
@NoArgsConstructor
public class BuyerRequirement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "buyer_id", nullable = false)
    private Buyer buyer;

    @Enumerated(EnumType.STRING)
    @Column(name = "requirement_type", nullable = false)
    private RequirementType requirementType;

    /** Pre-serialized JSON text, not JsonNode — see AuditLog's javadoc for why. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(nullable = false)
    private String detail;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    public enum RequirementType {
        COMPLIANCE, QUALITY, DOCUMENT, COSTING_RULE, LEAD_TIME
    }
}

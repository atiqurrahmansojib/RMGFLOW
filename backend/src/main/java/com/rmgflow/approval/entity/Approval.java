package com.rmgflow.approval.entity;

import com.rmgflow.identity.entity.Organization;
import com.rmgflow.identity.entity.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

/**
 * Document 8.4/ADR-08: the single shared state-machine table for every approval
 * gate (costing, quotation, sample, quality, shipment, documents). (targetType,
 * targetId) is an application-validated polymorphic reference, not a DB FK — the
 * accepted trade-off that avoids 6+ nearly-identical approval tables (Doc 6.3/56
 * rule 7). A decided round (decided_at set) is never updated again — enforced by
 * a DB trigger (V12 migration), not just by this class having no "edit" method.
 */
@Entity
@Table(name = "approvals")
@Getter
@Setter
@NoArgsConstructor
public class Approval {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_type", nullable = false)
    private ApprovalTargetType targetType;

    @Column(name = "target_id", nullable = false)
    private Long targetId;

    @Column(name = "round_no", nullable = false)
    private int roundNo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ApprovalStatus status = ApprovalStatus.SUBMITTED;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "submitted_by")
    private User submittedBy;

    @Column(name = "submitted_at", nullable = false)
    private Instant submittedAt = Instant.now();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "decided_by")
    private User decidedBy;

    @Column(name = "decided_at")
    private Instant decidedAt;

    private String comments;

    @Column(name = "rejection_reason")
    private String rejectionReason;
}

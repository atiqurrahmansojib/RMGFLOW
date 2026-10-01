package com.rmgflow.order.entity;

import com.rmgflow.identity.entity.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

/**
 * Document 9.4: append-only amendment log. A decided row (APPROVED/REJECTED) is
 * never re-decided — enforced by a DB trigger (V19 migration), same pattern as
 * approvals. Senior Merchandiser can only create REQUESTED rows; only a GM/Owner
 * holding ORDER_AMEND_APPROVE can transition one to APPROVED or REJECTED
 * (OrderAmendmentService), and approval is the ONLY code path that also updates
 * the order's live field — in the same transaction as this row's decision.
 */
@Entity
@Table(name = "order_amendments")
@Getter
@Setter
@NoArgsConstructor
public class OrderAmendment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @Column(name = "amendment_no", nullable = false)
    private int amendmentNo;

    @Column(name = "field_changed", nullable = false)
    private String fieldChanged;

    @Column(name = "old_value")
    private String oldValue;

    @Column(name = "new_value")
    private String newValue;

    @Column(nullable = false)
    private String reason;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requested_by")
    private User requestedBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by")
    private User approvedBy;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderAmendmentStatus status = OrderAmendmentStatus.REQUESTED;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "decided_at")
    private Instant decidedAt;
}

package com.rmgflow.ta.entity;

import com.rmgflow.factory.entity.Factory;
import com.rmgflow.identity.entity.User;
import com.rmgflow.masterdata.entity.MilestoneType;
import com.rmgflow.order.entity.Order;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;

/** Document 8.7: the per-order instantiated, mutable-by-actual-date milestone. */
@Entity
@Table(name = "ta_milestones")
@Getter
@Setter
@NoArgsConstructor
public class TaMilestone {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "milestone_type_id", nullable = false)
    private MilestoneType milestoneType;

    @Column(nullable = false)
    private int sequence;

    @Column(name = "planned_date", nullable = false)
    private LocalDate plannedDate;

    @Column(name = "revised_date")
    private LocalDate revisedDate;

    @Column(name = "actual_date")
    private LocalDate actualDate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "responsible_user_id")
    private User responsibleUser;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "responsible_factory_id")
    private Factory responsibleFactory;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TaMilestoneStatus status = TaMilestoneStatus.PENDING;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "depends_on_milestone_id")
    private TaMilestone dependsOnMilestone;

    @Column(name = "delay_reason")
    private String delayReason;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    /** Document 9.5: the date actually used for scheduling math — revised if set, else planned. */
    @Transient
    public LocalDate getEffectiveDate() {
        return revisedDate != null ? revisedDate : plannedDate;
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = Instant.now();
    }
}

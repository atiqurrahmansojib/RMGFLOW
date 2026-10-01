package com.rmgflow.ta.entity;

import com.rmgflow.masterdata.entity.MilestoneType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "ta_template_milestones", uniqueConstraints = @UniqueConstraint(columnNames = {"template_id", "sequence"}))
@Getter
@Setter
@NoArgsConstructor
public class TaTemplateMilestone {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "template_id", nullable = false)
    private TaTemplate template;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "milestone_type_id", nullable = false)
    private MilestoneType milestoneType;

    @Column(nullable = false)
    private int sequence;

    @Column(name = "offset_days_from_exfactory", nullable = false)
    private int offsetDaysFromExfactory;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "depends_on_milestone_id")
    private TaTemplateMilestone dependsOnMilestone;
}

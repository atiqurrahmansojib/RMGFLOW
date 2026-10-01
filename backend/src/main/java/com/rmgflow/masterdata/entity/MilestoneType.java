package com.rmgflow.masterdata.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "milestone_types")
@Getter
@Setter
@NoArgsConstructor
public class MilestoneType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @Column(name = "default_sequence", nullable = false)
    private int defaultSequence;

    @Column(name = "typical_offset_days")
    private Integer typicalOffsetDays;
}

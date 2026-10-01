package com.rmgflow.sample.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;

/** Document 9.3/FR-41/42: append-only — rejection creates a NEW revision, never
 * mutates this one. There is no update endpoint for an existing revision. */
@Entity
@Table(name = "sample_revisions")
@Getter
@Setter
@NoArgsConstructor
public class SampleRevision {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "sample_id", nullable = false)
    private Sample sample;

    @Column(name = "revision_no", nullable = false)
    private int revisionNo;

    @Column(name = "submitted_date")
    private LocalDate submittedDate;

    private String comments;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}

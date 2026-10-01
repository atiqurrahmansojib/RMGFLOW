package com.rmgflow.inquiry.entity;

import com.rmgflow.factory.entity.Factory;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "inquiry_factory_candidates", uniqueConstraints = @UniqueConstraint(columnNames = {"inquiry_id", "factory_id"}))
@Getter
@Setter
@NoArgsConstructor
public class InquiryFactoryCandidate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "inquiry_id", nullable = false)
    private Inquiry inquiry;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "factory_id", nullable = false)
    private Factory factory;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private InquiryFactoryCandidateStatus status = InquiryFactoryCandidateStatus.CANDIDATE;
}

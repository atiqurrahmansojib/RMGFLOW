package com.rmgflow.quality.entity;

import com.rmgflow.attachment.entity.Attachment;
import com.rmgflow.masterdata.entity.DefectType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "defects")
@Getter
@Setter
@NoArgsConstructor
public class Defect {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "inspection_id", nullable = false)
    private Inspection inspection;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "defect_type_id", nullable = false)
    private DefectType defectType;

    @Column(nullable = false)
    private int quantity;

    @Column(nullable = false)
    private String severity;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "photo_document_id")
    private Attachment photoDocument;
}

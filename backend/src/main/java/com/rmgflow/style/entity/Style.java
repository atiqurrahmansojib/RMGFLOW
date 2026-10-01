package com.rmgflow.style.entity;

import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.identity.entity.Organization;
import com.rmgflow.masterdata.entity.Season;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

/** Document 8.3/9/FR-30-31: style master. `currentRevisionId` is a denormalized pointer
 * for fast "latest" lookups; style_revisions is the append-only source of truth. */
@Entity
@Table(name = "styles")
@Getter
@Setter
@NoArgsConstructor
public class Style {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(name = "style_no", nullable = false, unique = true)
    private String styleNo;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "buyer_id", nullable = false)
    private Buyer buyer;

    @Column(name = "buyer_style_no")
    private String buyerStyleNo;

    @Column(name = "product_category")
    private String productCategory;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "season_id")
    private Season season;

    private String gender;

    private String description;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "current_revision_id")
    private StyleRevision currentRevision;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = Instant.now();
    }
}

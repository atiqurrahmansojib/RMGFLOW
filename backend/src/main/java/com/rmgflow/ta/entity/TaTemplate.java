package com.rmgflow.ta.entity;

import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.identity.entity.Organization;
import com.rmgflow.style.entity.Style;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

/** Document 8.7: reusable configuration, resolved by specificity at order
 * confirmation (style-specific > buyer-specific > org default, Doc 10.3). */
@Entity
@Table(name = "ta_templates")
@Getter
@Setter
@NoArgsConstructor
public class TaTemplate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(nullable = false)
    private String name;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "buyer_id")
    private Buyer buyer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "style_id")
    private Style style;

    @Column(name = "is_default", nullable = false)
    private boolean isDefault;

    @OneToMany(mappedBy = "template", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<TaTemplateMilestone> milestones = new ArrayList<>();
}

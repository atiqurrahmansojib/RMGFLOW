package com.rmgflow.shipment.entity;

import com.rmgflow.factory.entity.Factory;
import com.rmgflow.identity.entity.Organization;
import com.rmgflow.identity.entity.User;
import com.rmgflow.order.entity.Order;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Document 8.8/9.8: SUM(quantity_shipped) across all shipments for an order must
 * never exceed the order's total quantity — hard-blocked, no override, ever (Doc
 * 9.8/9.11 invariant #5). A partial shipment (less than the remaining quantity)
 * requires authorized_by to be set by a SHIPMENT_PARTIAL_AUTHORIZE holder, and
 * creation itself is blocked unless the order has a passing FINAL inspection
 * (Doc 9.7) or an explicit SHIPMENT_QUALITY_OVERRIDE-permission-gated override
 * with a recorded reason (same pattern as Doc 9.4's factory-approval override).
 */
@Entity
@Table(name = "shipments")
@Getter
@Setter
@NoArgsConstructor
public class Shipment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(name = "shipment_no", nullable = false, unique = true)
    private String shipmentNo;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @Column(name = "shipment_date")
    private LocalDate shipmentDate;

    private LocalDate etd;
    private LocalDate eta;

    @Column(name = "quantity_shipped", nullable = false)
    private int quantityShipped;

    private Integer cartons;

    @Column(name = "gross_weight")
    private BigDecimal grossWeight;

    @Column(name = "net_weight")
    private BigDecimal netWeight;

    @Column(name = "volume_cbm")
    private BigDecimal volumeCbm;

    @Column(name = "port_of_loading")
    private String portOfLoading;

    @Column(name = "port_of_discharge")
    private String portOfDischarge;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "forwarder_id")
    private Factory forwarder;

    @Column(name = "shipping_line")
    private String shippingLine;

    @Column(name = "container_no")
    private String containerNo;

    @Column(name = "bl_awb_no")
    private String blAwbNo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ShipmentStatus status = ShipmentStatus.BOOKED;

    @Column(name = "is_partial", nullable = false)
    private boolean partial;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "authorized_by")
    private User authorizedBy;

    @Column(name = "override_reason")
    private String overrideReason;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}

package com.rmgflow.order.service;

/**
 * Published (synchronously, inside the creating transaction) when an order is
 * confirmed, so T&A can auto-generate its plan (Doc A15) without OrderService
 * depending on the T&A module. {@code styleId} is the first line's style, used for
 * style-specific template resolution.
 */
public record OrderConfirmedEvent(Long orderId, Long styleId) {
}

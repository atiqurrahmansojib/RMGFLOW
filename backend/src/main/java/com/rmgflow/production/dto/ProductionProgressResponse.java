package com.rmgflow.production.dto;

import java.util.List;

/** Document 9.6/14.4: the cumulative rollup and planned-vs-actual view — always
 * computed from production_updates, never a stored running total. */
public record ProductionProgressResponse(
        Long orderId, int orderQuantity, int cumulativeCutting, int cumulativeSewing,
        int cumulativeFinishing, int cumulativePacking, int cumulativeRejection, int cumulativeAlteration,
        double packingProgressPercent, List<ProductionUpdateResponse> dailyUpdates
) {
}

package com.rmgflow.financial.service;

import com.rmgflow.common.ApiException;
import com.rmgflow.financial.dto.OrderFinancialsRequest;
import com.rmgflow.financial.dto.OrderFinancialsResponse;
import com.rmgflow.financial.entity.OrderFinancials;
import com.rmgflow.financial.repository.OrderFinancialsRepository;
import com.rmgflow.order.entity.Order;
import com.rmgflow.order.service.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Document 9.10/ADR-12: operational profitability ONLY — not a general ledger.
 * operational_margin_percent is computed here, server-side, every time (NFR-01):
 * (realizedUnitPrice - actualCostUnit) / realizedUnitPrice * 100 once a realized
 * price is recorded; before that it falls back to an ESTIMATE using quotedUnitPrice,
 * with the response's isEstimate flag telling the caller which basis was used —
 * never silently presenting an estimate as the final, realized figure.
 */
@Service
@RequiredArgsConstructor
public class OrderFinancialsService {

    private final OrderFinancialsRepository orderFinancialsRepository;
    private final OrderService orderService;

    @Transactional
    public OrderFinancialsResponse upsert(Long orderId, OrderFinancialsRequest request) {
        Order order = orderService.findInCurrentOrganization(orderId);
        OrderFinancials financials = orderFinancialsRepository.findByOrderId(orderId).orElseGet(OrderFinancials::new);
        financials.setOrder(order);
        financials.setQuotedUnitPrice(request.quotedUnitPrice());
        financials.setActualCostUnit(request.actualCostUnit());
        financials.setRealizedUnitPrice(request.realizedUnitPrice());
        financials = orderFinancialsRepository.save(financials);
        return toResponse(financials);
    }

    @Transactional(readOnly = true)
    public OrderFinancialsResponse get(Long orderId) {
        orderService.findInCurrentOrganization(orderId);
        return orderFinancialsRepository.findByOrderId(orderId)
                .map(this::toResponse)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "No financial record exists for this order yet"));
    }

    private OrderFinancialsResponse toResponse(OrderFinancials financials) {
        BigDecimal cost = financials.getActualCostUnit();
        boolean useRealized = financials.getRealizedUnitPrice() != null;
        BigDecimal basisPrice = useRealized ? financials.getRealizedUnitPrice() : financials.getQuotedUnitPrice();

        BigDecimal marginPercent = null;
        if (basisPrice != null && cost != null && basisPrice.compareTo(BigDecimal.ZERO) > 0) {
            marginPercent = basisPrice.subtract(cost)
                    .divide(basisPrice, 6, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100))
                    .setScale(3, RoundingMode.HALF_UP);
        }

        return new OrderFinancialsResponse(financials.getId(), financials.getOrder().getId(),
                financials.getQuotedUnitPrice(), financials.getActualCostUnit(), financials.getRealizedUnitPrice(),
                marginPercent, !useRealized);
    }
}

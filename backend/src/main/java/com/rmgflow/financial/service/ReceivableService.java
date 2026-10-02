package com.rmgflow.financial.service;

import com.rmgflow.buyer.entity.Buyer;
import com.rmgflow.buyer.service.BuyerService;
import com.rmgflow.common.ApiException;
import com.rmgflow.financial.dto.ReceivableRequest;
import com.rmgflow.financial.dto.ReceivableResponse;
import com.rmgflow.financial.entity.Receivable;
import com.rmgflow.financial.repository.ReceivableRepository;
import com.rmgflow.masterdata.repository.CurrencyRepository;
import com.rmgflow.order.entity.Order;
import com.rmgflow.order.service.OrderService;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/** Document 9.10: status (PENDING/PARTIAL/RECEIVED/OVERDUE) is always derived —
 * never a field a caller can set directly. */
@Service
@RequiredArgsConstructor
public class ReceivableService {

    private final ReceivableRepository receivableRepository;
    private final OrderService orderService;
    private final BuyerService buyerService;
    private final CurrencyRepository currencyRepository;

    @Transactional
    public ReceivableResponse create(Long orderId, ReceivableRequest request) {
        Order order = orderService.findInCurrentOrganization(orderId);
        Buyer buyer = buyerService.findInCurrentOrganization(request.buyerId());
        if (!currencyRepository.existsById(request.currency())) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Currency not found");
        }

        Receivable receivable = new Receivable();
        receivable.setOrder(order);
        receivable.setBuyer(buyer);
        receivable.setAmount(request.amount());
        receivable.setCurrency(currencyRepository.getReferenceById(request.currency()));
        receivable.setDueDate(request.dueDate());
        receivable = receivableRepository.save(receivable);
        return toResponse(receivable);
    }

    @Transactional(readOnly = true)
    public List<ReceivableResponse> listByOrder(Long orderId) {
        orderService.findInCurrentOrganization(orderId);
        return receivableRepository.findByOrderId(orderId).stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<ReceivableResponse> listAll() {
        Long organizationId = ((AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal()).organizationId();
        return receivableRepository.findByOrder_Organization_Id(organizationId).stream().map(this::toResponse).toList();
    }

    public Receivable findInCurrentOrganization(Long receivableId) {
        Long organizationId = ((AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal()).organizationId();
        return receivableRepository.findByIdAndOrder_Organization_Id(receivableId, organizationId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Receivable not found"));
    }

    @Transactional
    public void applyPayment(Receivable receivable, BigDecimal amount) {
        receivable.setReceivedAmount(receivable.getReceivedAmount().add(amount));
        receivableRepository.save(receivable);
    }

    private ReceivableResponse toResponse(Receivable receivable) {
        String status;
        if (receivable.getDueDate().isBefore(LocalDate.now()) && receivable.getReceivedAmount().compareTo(receivable.getAmount()) < 0) {
            status = "OVERDUE";
        } else if (receivable.getReceivedAmount().compareTo(receivable.getAmount()) >= 0) {
            status = "RECEIVED";
        } else if (receivable.getReceivedAmount().compareTo(BigDecimal.ZERO) > 0) {
            status = "PARTIAL";
        } else {
            status = "PENDING";
        }
        return new ReceivableResponse(receivable.getId(), receivable.getOrder().getId(), receivable.getBuyer().getId(),
                receivable.getAmount(), receivable.getCurrency().getCode(), receivable.getDueDate(),
                receivable.getReceivedAmount(), status);
    }
}

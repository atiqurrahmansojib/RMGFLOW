package com.rmgflow.financial.service;

import com.rmgflow.common.ApiException;
import com.rmgflow.factory.entity.Factory;
import com.rmgflow.factory.service.FactoryService;
import com.rmgflow.financial.dto.PayableRequest;
import com.rmgflow.financial.dto.PayableResponse;
import com.rmgflow.financial.entity.Payable;
import com.rmgflow.financial.repository.PayableRepository;
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

@Service
@RequiredArgsConstructor
public class PayableService {

    private final PayableRepository payableRepository;
    private final OrderService orderService;
    private final FactoryService factoryService;
    private final CurrencyRepository currencyRepository;

    @Transactional
    public PayableResponse create(Long orderId, PayableRequest request) {
        Order order = orderService.findInCurrentOrganization(orderId);
        Factory factory = factoryService.findInCurrentOrganization(request.factoryId());
        if (!currencyRepository.existsById(request.currency())) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Currency not found");
        }

        Payable payable = new Payable();
        payable.setOrder(order);
        payable.setFactory(factory);
        payable.setAmount(request.amount());
        payable.setCurrency(currencyRepository.getReferenceById(request.currency()));
        payable.setDueDate(request.dueDate());
        payable = payableRepository.save(payable);
        return toResponse(payable);
    }

    @Transactional(readOnly = true)
    public List<PayableResponse> listByOrder(Long orderId) {
        orderService.findInCurrentOrganization(orderId);
        return payableRepository.findByOrderId(orderId).stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<PayableResponse> listAll() {
        Long organizationId = ((AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal()).organizationId();
        return payableRepository.findByOrder_Organization_Id(organizationId).stream().map(this::toResponse).toList();
    }

    public Payable findInCurrentOrganization(Long payableId) {
        Long organizationId = ((AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal()).organizationId();
        return payableRepository.findByIdAndOrder_Organization_Id(payableId, organizationId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Payable not found"));
    }

    @Transactional
    public void applyPayment(Payable payable, BigDecimal amount) {
        payable.setPaidAmount(payable.getPaidAmount().add(amount));
        payableRepository.save(payable);
    }

    private PayableResponse toResponse(Payable payable) {
        String status;
        if (payable.getDueDate().isBefore(LocalDate.now()) && payable.getPaidAmount().compareTo(payable.getAmount()) < 0) {
            status = "OVERDUE";
        } else if (payable.getPaidAmount().compareTo(payable.getAmount()) >= 0) {
            status = "PAID";
        } else if (payable.getPaidAmount().compareTo(BigDecimal.ZERO) > 0) {
            status = "PARTIAL";
        } else {
            status = "PENDING";
        }
        return new PayableResponse(payable.getId(), payable.getOrder().getId(), payable.getFactory().getId(),
                payable.getAmount(), payable.getCurrency().getCode(), payable.getDueDate(), payable.getPaidAmount(), status);
    }
}

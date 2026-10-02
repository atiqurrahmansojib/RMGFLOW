package com.rmgflow.financial.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.common.ApiException;
import com.rmgflow.financial.dto.PaymentRecordRequest;
import com.rmgflow.financial.dto.PaymentRecordResponse;
import com.rmgflow.financial.entity.Payable;
import com.rmgflow.financial.entity.PaymentRecord;
import com.rmgflow.financial.entity.Receivable;
import com.rmgflow.financial.repository.PaymentRecordRepository;
import com.rmgflow.identity.repository.UserRepository;
import com.rmgflow.security.AuthenticatedUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Document 9.10: recording a payment atomically creates the payment_records row
 * AND bumps the receivable/payable's running received/paid amount — never one
 * without the other (same "write log + update current value together" discipline
 * as order amendments, Doc 9.4). */
@Service
@RequiredArgsConstructor
public class PaymentRecordService {

    private final PaymentRecordRepository paymentRecordRepository;
    private final ReceivableService receivableService;
    private final PayableService payableService;
    private final UserRepository userRepository;
    private final AuditService auditService;

    @Transactional
    public PaymentRecordResponse record(PaymentRecordRequest request) {
        if (request.receivableId() == null && request.payableId() == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "A payment record must reference a receivable or a payable");
        }

        PaymentRecord payment = new PaymentRecord();
        Receivable receivable = null;
        Payable payable = null;
        if (request.receivableId() != null) {
            receivable = receivableService.findInCurrentOrganization(request.receivableId());
            payment.setReceivable(receivable);
        }
        if (request.payableId() != null) {
            payable = payableService.findInCurrentOrganization(request.payableId());
            payment.setPayable(payable);
        }
        payment.setAmount(request.amount());
        payment.setPaidDate(request.paidDate());
        payment.setMethod(request.method());
        payment.setReferenceNo(request.referenceNo());
        payment.setRecordedBy(userRepository.getReferenceById(currentUser().id()));
        payment = paymentRecordRepository.save(payment);

        if (receivable != null) {
            receivableService.applyPayment(receivable, request.amount());
        }
        if (payable != null) {
            payableService.applyPayment(payable, request.amount());
        }

        auditService.record("PAYMENT_RECORD", receivable != null ? "Receivable" : "Payable",
                receivable != null ? receivable.getId() : payable.getId(), null, toResponse(payment), null);
        return toResponse(payment);
    }

    private PaymentRecordResponse toResponse(PaymentRecord payment) {
        return new PaymentRecordResponse(payment.getId(),
                payment.getReceivable() != null ? payment.getReceivable().getId() : null,
                payment.getPayable() != null ? payment.getPayable().getId() : null,
                payment.getAmount(), payment.getPaidDate(), payment.getMethod(), payment.getReferenceNo());
    }

    private AuthenticatedUser currentUser() {
        return (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }
}

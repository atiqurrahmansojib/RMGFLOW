package com.rmgflow.quality.service;

import com.rmgflow.audit.service.AuditService;
import com.rmgflow.common.ApiException;
import com.rmgflow.quality.dto.CapaFactoryResponseRequest;
import com.rmgflow.quality.dto.CapaRecordRequest;
import com.rmgflow.quality.dto.CapaRecordResponse;
import com.rmgflow.quality.entity.CapaRecord;
import com.rmgflow.quality.entity.CapaStatus;
import com.rmgflow.quality.entity.Defect;
import com.rmgflow.quality.entity.Inspection;
import com.rmgflow.quality.repository.CapaRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

/** Document 9.7/15/CAPA: corrective/preventive action tracking against a defect or
 * an inspection directly. Document 9.7's "CAPA must close before a FINAL-gating
 * milestone completes" wiring is deferred — it would couple this module to T&A's
 * milestone-completion concept, which doesn't have an explicit "complete" action
 * yet (only actual_date recording); revisit once that's clarified rather than
 * bolting on a half-correct cross-module rule now. */
@Service
@RequiredArgsConstructor
public class CapaRecordService {

    private final CapaRecordRepository capaRecordRepository;
    private final DefectService defectService;
    private final InspectionService inspectionService;
    private final AuditService auditService;

    @Transactional
    public CapaRecordResponse create(CapaRecordRequest request) {
        if (request.defectId() == null && request.inspectionId() == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "A CAPA record must reference a defect or an inspection");
        }

        CapaRecord capa = new CapaRecord();
        if (request.defectId() != null) {
            Defect defect = defectService.findInCurrentOrganization(request.defectId());
            capa.setDefect(defect);
        }
        if (request.inspectionId() != null) {
            Inspection inspection = inspectionService.findInCurrentOrganization(request.inspectionId());
            capa.setInspection(inspection);
        }
        capa.setDescription(request.description());
        capa.setCorrectiveAction(request.correctiveAction());
        capa.setPreventiveAction(request.preventiveAction());
        capa = capaRecordRepository.save(capa);

        auditService.record("CAPA_CREATE", "CapaRecord", capa.getId(), null, toResponse(capa), null);
        return toResponse(capa);
    }

    @Transactional
    public CapaRecordResponse recordFactoryResponse(Long capaId, CapaFactoryResponseRequest request) {
        CapaRecord capa = findInCurrentOrganization(capaId);
        capa.setFactoryResponse(request.factoryResponse());
        if (capa.getStatus() == CapaStatus.OPEN) {
            capa.setStatus(CapaStatus.IN_PROGRESS);
        }
        capa = capaRecordRepository.save(capa);
        return toResponse(capa);
    }

    @Transactional
    public CapaRecordResponse close(Long capaId) {
        CapaRecord capa = findInCurrentOrganization(capaId);
        if (capa.getStatus() == CapaStatus.CLOSED) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "This CAPA record is already closed");
        }
        capa.setStatus(CapaStatus.CLOSED);
        capa.setClosedAt(Instant.now());
        capa = capaRecordRepository.save(capa);
        auditService.record("CAPA_CLOSE", "CapaRecord", capa.getId(), CapaStatus.OPEN, CapaStatus.CLOSED, null);
        return toResponse(capa);
    }

    @Transactional(readOnly = true)
    public List<CapaRecordResponse> listByDefect(Long defectId) {
        defectService.findInCurrentOrganization(defectId);
        return capaRecordRepository.findByDefectId(defectId).stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<CapaRecordResponse> listByInspection(Long inspectionId) {
        inspectionService.findInCurrentOrganization(inspectionId);
        return capaRecordRepository.findByInspectionId(inspectionId).stream().map(this::toResponse).toList();
    }

    private CapaRecord findInCurrentOrganization(Long capaId) {
        CapaRecord capa = capaRecordRepository.findById(capaId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "CAPA record not found"));
        // Tenant check via whichever source is set — throws 404 if it doesn't resolve.
        if (capa.getDefect() != null) {
            defectService.findInCurrentOrganization(capa.getDefect().getId());
        } else {
            inspectionService.findInCurrentOrganization(capa.getInspection().getId());
        }
        return capa;
    }

    private CapaRecordResponse toResponse(CapaRecord capa) {
        return new CapaRecordResponse(capa.getId(), capa.getDefect() != null ? capa.getDefect().getId() : null,
                capa.getInspection() != null ? capa.getInspection().getId() : null, capa.getDescription(),
                capa.getCorrectiveAction(), capa.getPreventiveAction(), capa.getFactoryResponse(),
                capa.getStatus(), capa.getCreatedAt(), capa.getClosedAt());
    }
}

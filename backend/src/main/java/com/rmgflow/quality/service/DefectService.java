package com.rmgflow.quality.service;

import com.rmgflow.common.ApiException;
import com.rmgflow.masterdata.repository.DefectTypeRepository;
import com.rmgflow.quality.dto.DefectRequest;
import com.rmgflow.quality.dto.DefectResponse;
import com.rmgflow.quality.entity.Defect;
import com.rmgflow.quality.entity.Inspection;
import com.rmgflow.quality.repository.DefectRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class DefectService {

    private final DefectRepository defectRepository;
    private final InspectionService inspectionService;
    private final DefectTypeRepository defectTypeRepository;

    @Transactional
    public DefectResponse create(Long inspectionId, DefectRequest request) {
        Inspection inspection = inspectionService.findInCurrentOrganization(inspectionId);
        if (!defectTypeRepository.existsById(request.defectTypeId())) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Defect type not found");
        }

        Defect defect = new Defect();
        defect.setInspection(inspection);
        defect.setDefectType(defectTypeRepository.getReferenceById(request.defectTypeId()));
        defect.setQuantity(request.quantity());
        defect.setSeverity(request.severity());
        defect = defectRepository.save(defect);
        return toResponse(defect);
    }

    @Transactional(readOnly = true)
    public List<DefectResponse> list(Long inspectionId) {
        inspectionService.findInCurrentOrganization(inspectionId);
        return defectRepository.findByInspectionId(inspectionId).stream().map(this::toResponse).toList();
    }

    public Defect findInCurrentOrganization(Long defectId) {
        Defect defect = defectRepository.findById(defectId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Defect not found"));
        // Tenant check by resolving the defect's inspection within the caller's org —
        // throws 404 if it doesn't resolve, same effect as a direct scoped query.
        inspectionService.findInCurrentOrganization(defect.getInspection().getId());
        return defect;
    }

    private DefectResponse toResponse(Defect defect) {
        return new DefectResponse(defect.getId(), defect.getInspection().getId(), defect.getDefectType().getId(),
                defect.getQuantity(), defect.getSeverity(), defect.getPhotoDocument() != null ? defect.getPhotoDocument().getId() : null);
    }
}

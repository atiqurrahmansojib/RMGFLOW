package com.rmgflow.document.repository;

import com.rmgflow.document.entity.CommercialDocument;
import com.rmgflow.document.entity.DocumentEntityType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CommercialDocumentRepository extends JpaRepository<CommercialDocument, Long> {
    List<CommercialDocument> findByEntityTypeAndEntityIdAndOrganizationId(DocumentEntityType entityType, Long entityId, Long organizationId);

    Optional<CommercialDocument> findTopByEntityTypeAndEntityIdAndDocumentTypeIdOrderByVersionNoDesc(
            DocumentEntityType entityType, Long entityId, Long documentTypeId);

    Optional<CommercialDocument> findByIdAndOrganizationId(Long id, Long organizationId);
}

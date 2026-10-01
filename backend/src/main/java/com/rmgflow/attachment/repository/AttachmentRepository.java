package com.rmgflow.attachment.repository;

import com.rmgflow.attachment.entity.Attachment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AttachmentRepository extends JpaRepository<Attachment, Long> {
    List<Attachment> findByEntityTypeAndEntityIdAndOrganizationId(String entityType, Long entityId, Long organizationId);

    Optional<Attachment> findByIdAndOrganizationId(Long id, Long organizationId);
}

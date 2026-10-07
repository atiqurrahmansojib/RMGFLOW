package com.rmgflow.approval.repository;

import com.rmgflow.approval.entity.Approval;
import com.rmgflow.approval.entity.ApprovalStatus;
import com.rmgflow.approval.entity.ApprovalTargetType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ApprovalRepository extends JpaRepository<Approval, Long> {
    List<Approval> findByOrganizationIdAndTargetTypeAndTargetIdOrderByRoundNoDesc(Long organizationId, ApprovalTargetType targetType, Long targetId);

    Optional<Approval> findTopByTargetTypeAndTargetIdOrderByRoundNoDesc(ApprovalTargetType targetType, Long targetId);

    Optional<Approval> findTopByOrganizationIdAndTargetTypeAndTargetIdOrderByRoundNoDesc(Long organizationId, ApprovalTargetType targetType, Long targetId);

    Optional<Approval> findByIdAndOrganizationId(Long id, Long organizationId);

    Page<Approval> findByOrganizationIdAndStatus(Long organizationId, ApprovalStatus status, Pageable pageable);

    Page<Approval> findByOrganizationIdAndTargetTypeInAndStatus(Long organizationId, java.util.Collection<ApprovalTargetType> targetTypes, ApprovalStatus status, Pageable pageable);

    Page<Approval> findByOrganizationIdAndTargetTypeAndStatus(Long organizationId, ApprovalTargetType targetType, ApprovalStatus status, Pageable pageable);
}

package com.rmgflow.inquiry.repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Collection;

import com.rmgflow.inquiry.entity.Inquiry;
import com.rmgflow.inquiry.entity.InquiryStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface InquiryRepository extends JpaRepository<Inquiry, Long> {
    boolean existsByInquiryNoIgnoreCase(String inquiryNo);

    Optional<Inquiry> findByIdAndOrganizationId(Long id, Long organizationId);

    Page<Inquiry> findByOrganizationId(Long organizationId, Pageable pageable);

    Page<Inquiry> findByOrganizationIdAndStatus(Long organizationId, InquiryStatus status, Pageable pageable);

    /** Doc 5.3 object-level scope: org + (unrestricted OR assigned buyer/factory). */
    @Query("select q from Inquiry q where q.organization.id = :orgId and (:status is null or q.status = :status)"
            + " and (:all = true or q.buyer.id in :buyerIds or exists (select c.id from InquiryFactoryCandidate c where c.inquiry = q and c.factory.id in :factoryIds))")
    Page<Inquiry> findVisible(@Param("orgId") Long orgId, @Param("status") InquiryStatus status, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds, Pageable pageable);

    @Query("select q from Inquiry q where q.id = :id and q.organization.id = :orgId"
            + " and (:all = true or q.buyer.id in :buyerIds or exists (select c.id from InquiryFactoryCandidate c where c.inquiry = q and c.factory.id in :factoryIds))")
    Optional<Inquiry> findVisibleById(@Param("id") Long id, @Param("orgId") Long orgId, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds);
}

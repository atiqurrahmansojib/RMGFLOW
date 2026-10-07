package com.rmgflow.sample.repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Collection;

import com.rmgflow.sample.entity.Sample;
import com.rmgflow.sample.entity.SampleStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SampleRepository extends JpaRepository<Sample, Long> {
    boolean existsBySampleNoIgnoreCase(String sampleNo);

    Optional<Sample> findByIdAndOrganizationId(Long id, Long organizationId);

    Page<Sample> findByOrganizationId(Long organizationId, Pageable pageable);

    Page<Sample> findByOrganizationIdAndCurrentStatus(Long organizationId, SampleStatus status, Pageable pageable);

    /** Doc 5.3 object-level scope: org + (unrestricted OR assigned buyer/factory). */
    @Query("select s from Sample s where s.organization.id = :orgId and (:status is null or s.currentStatus = :status)"
            + " and (:all = true or s.buyer.id in :buyerIds or s.factory.id in :factoryIds)")
    Page<Sample> findVisible(@Param("orgId") Long orgId, @Param("status") SampleStatus status, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds, Pageable pageable);

    @Query("select s from Sample s where s.id = :id and s.organization.id = :orgId"
            + " and (:all = true or s.buyer.id in :buyerIds or s.factory.id in :factoryIds)")
    Optional<Sample> findVisibleById(@Param("id") Long id, @Param("orgId") Long orgId, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds);
}

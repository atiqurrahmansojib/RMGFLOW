package com.rmgflow.sample.repository;

import com.rmgflow.sample.entity.SampleType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SampleTypeRepository extends JpaRepository<SampleType, Long> {

    /** Standard types (no buyer) plus the buyer-specific types of the caller's own buyers —
     *  sample_types has no organization column, so tenancy comes through the buyer. */
    @Query("select t from SampleType t left join t.buyer b "
            + "where b is null or b.organization.id = :organizationId order by t.id")
    List<SampleType> findVisibleToOrganization(@Param("organizationId") Long organizationId);

    @Query("select count(t) > 0 from SampleType t left join t.buyer b "
            + "where t.id = :id and (b is null or b.organization.id = :organizationId)")
    boolean existsVisibleToOrganization(@Param("id") Long id, @Param("organizationId") Long organizationId);
}

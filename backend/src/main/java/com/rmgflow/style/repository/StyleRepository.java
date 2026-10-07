package com.rmgflow.style.repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Collection;

import com.rmgflow.style.entity.Style;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface StyleRepository extends JpaRepository<Style, Long> {
    boolean existsByStyleNoIgnoreCase(String styleNo);

    Optional<Style> findByIdAndOrganizationId(Long id, Long organizationId);

    Page<Style> findByOrganizationIdAndActiveTrue(Long organizationId, Pageable pageable);

    Page<Style> findByOrganizationIdAndActiveTrueAndStyleNoContainingIgnoreCase(Long organizationId, String styleNoFragment, Pageable pageable);

    /** Doc 5.3 object-level scope: org + (unrestricted OR assigned buyer/factory). */
    @Query("select s from Style s where s.organization.id = :orgId and s.active = true and lower(s.styleNo) like lower(concat('%', :search, '%'))"
            + " and (:all = true or s.buyer.id in :buyerIds or exists (select i.id from OrderItem i where i.style = s and i.factory.id in :factoryIds))")
    Page<Style> findVisible(@Param("orgId") Long orgId, @Param("search") String search, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds, Pageable pageable);

    @Query("select s from Style s where s.id = :id and s.organization.id = :orgId"
            + " and (:all = true or s.buyer.id in :buyerIds or exists (select i.id from OrderItem i where i.style = s and i.factory.id in :factoryIds))")
    Optional<Style> findVisibleById(@Param("id") Long id, @Param("orgId") Long orgId, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds);
}

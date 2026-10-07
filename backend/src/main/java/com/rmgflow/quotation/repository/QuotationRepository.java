package com.rmgflow.quotation.repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Collection;

import com.rmgflow.quotation.entity.Quotation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface QuotationRepository extends JpaRepository<Quotation, Long> {
    boolean existsByQuotationNoIgnoreCase(String quotationNo);

    Optional<Quotation> findByIdAndOrganizationId(Long id, Long organizationId);

    Optional<Quotation> findTopByQuotationNoOrderByVersionNoDesc(String quotationNo);

    Page<Quotation> findByOrganizationIdAndBuyerId(Long organizationId, Long buyerId, Pageable pageable);

    Page<Quotation> findByOrganizationId(Long organizationId, Pageable pageable);

    /** Doc 5.3 object-level scope: org + (unrestricted OR assigned buyer/factory). */
    @Query("select q from Quotation q where q.organization.id = :orgId and (:buyerId is null or q.buyer.id = :buyerId)"
            + " and (:all = true or q.buyer.id in :buyerIds or exists (select i.id from OrderItem i where i.style = q.style and i.factory.id in :factoryIds))")
    Page<Quotation> findVisible(@Param("orgId") Long orgId, @Param("buyerId") Long buyerId, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds, Pageable pageable);

    @Query("select q from Quotation q where q.id = :id and q.organization.id = :orgId"
            + " and (:all = true or q.buyer.id in :buyerIds or exists (select i.id from OrderItem i where i.style = q.style and i.factory.id in :factoryIds))")
    Optional<Quotation> findVisibleById(@Param("id") Long id, @Param("orgId") Long orgId, @Param("all") boolean all, @Param("buyerIds") Collection<Long> buyerIds, @Param("factoryIds") Collection<Long> factoryIds);
}

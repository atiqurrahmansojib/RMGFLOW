package com.rmgflow.identity.repository;

import com.rmgflow.identity.entity.Organization;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrganizationRepository extends JpaRepository<Organization, Long> {
}

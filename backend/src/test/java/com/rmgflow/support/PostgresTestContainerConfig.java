package com.rmgflow.support;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * Document 16.2: integration tests run against a real PostgreSQL (Testcontainers),
 * never H2 — several Doc 9 rules (triggers, CHECK constraints, append-only grants)
 * are Postgres-specific and would silently not be exercised by an in-memory DB.
 */
@TestConfiguration
public class PostgresTestContainerConfig {

    @Bean
    @ServiceConnection
    PostgreSQLContainer<?> postgresContainer() {
        return new PostgreSQLContainer<>(DockerImageName.parse("postgres:16-alpine"));
    }
}

package com.rmgflow.attachment.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "rmgflow.storage")
public record StorageProperties(String rootDirectory, long maxFileSizeBytes, int downloadTokenTtlMinutes) {
}

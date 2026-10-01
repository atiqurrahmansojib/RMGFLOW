package com.rmgflow.attachment.service;

import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;

/**
 * Document 15.4/ADR-06: abstraction over the underlying blob store. Swap
 * LocalFilesystemStorageService for a real S3/MinIO-backed implementation in
 * production (Doc 17.2) without touching AttachmentService.
 */
public interface StorageService {

    /** Allow-listed content types (Doc 15.4) — reject anything else before it touches disk. */
    java.util.Set<String> ALLOWED_CONTENT_TYPES = java.util.Set.of(
            "image/jpeg", "image/png", "image/webp", "image/heic",
            "application/pdf",
            "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    );

    /** Stores the file under a generated key; never trusts the caller-supplied filename for the key itself. */
    String store(MultipartFile file);

    InputStream retrieve(String storageKey);
}

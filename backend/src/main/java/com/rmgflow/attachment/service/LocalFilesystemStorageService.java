package com.rmgflow.attachment.service;

import com.rmgflow.attachment.config.StorageProperties;
import com.rmgflow.common.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;

/**
 * Document 15.4/17.2/ADR-06: deliberately simple placeholder — production should
 * point this at an S3-compatible bucket (see StorageService javadoc). Path
 * traversal is impossible by construction: the storage key is always a freshly
 * generated UUID, never derived from the caller-supplied filename.
 */
@Service
@RequiredArgsConstructor
public class LocalFilesystemStorageService implements StorageService {

    private final StorageProperties storageProperties;

    @Override
    public String store(MultipartFile file) {
        validate(file);
        try {
            Path root = Path.of(storageProperties.rootDirectory());
            Files.createDirectories(root);
            String key = UUID.randomUUID().toString();
            Path target = root.resolve(key);
            file.transferTo(target);
            return key;
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to store attachment", e);
        }
    }

    @Override
    public InputStream retrieve(String storageKey) {
        try {
            Path path = Path.of(storageProperties.rootDirectory()).resolve(storageKey);
            return Files.newInputStream(path);
        } catch (IOException e) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Attachment file not found");
        }
    }

    private void validate(MultipartFile file) {
        if (file.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "File is empty");
        }
        if (file.getSize() > storageProperties.maxFileSizeBytes()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "File exceeds the maximum allowed size");
        }
        String contentType = file.getContentType();
        if (contentType == null || !StorageService.ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "File type not allowed: " + contentType);
        }
    }
}

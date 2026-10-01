package com.rmgflow.attachment.controller;

import com.rmgflow.attachment.dto.AttachmentResponse;
import com.rmgflow.attachment.dto.DownloadUrlResponse;
import com.rmgflow.attachment.service.AttachmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/** Document 15.4/21 P3-T3: upload is direct-to-API (multipart); download goes through a
 * short-lived signed URL (getUrl -> download?token=) rather than exposing storage keys. */
@RestController
@RequestMapping("/api/v1/attachments")
@RequiredArgsConstructor
public class AttachmentController {

    private final AttachmentService attachmentService;

    @GetMapping
    @PreAuthorize("hasAuthority('ATTACHMENT_MANAGE')")
    public List<AttachmentResponse> list(@RequestParam String entityType, @RequestParam Long entityId) {
        return attachmentService.list(entityType, entityId);
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAuthority('ATTACHMENT_MANAGE')")
    public ResponseEntity<AttachmentResponse> upload(@RequestParam String entityType, @RequestParam Long entityId,
                                                      @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(attachmentService.upload(entityType, entityId, file));
    }

    @GetMapping("/{id}/url")
    @PreAuthorize("hasAuthority('ATTACHMENT_MANAGE')")
    public DownloadUrlResponse getDownloadUrl(@PathVariable Long id) {
        return attachmentService.getDownloadUrl(id);
    }

    /** No @PreAuthorize: authorization already happened when the signed token was
     * issued (getDownloadUrl) — the token itself, not a role, is the credential here,
     * matching Doc 15.4's "short-lived signed URL" model (anonymous bearer of a
     * valid, unexpired token may fetch exactly that one file). */
    @GetMapping("/download")
    public ResponseEntity<InputStreamResource> download(@RequestParam String token) {
        var result = attachmentService.download(token);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(result.contentType()))
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment().filename(result.fileName()).build().toString())
                .body(new InputStreamResource(result.stream()));
    }
}

package com.rmgflow.document.controller;

import com.rmgflow.document.dto.CommercialDocumentRequest;
import com.rmgflow.document.dto.CommercialDocumentResponse;
import com.rmgflow.document.entity.DocumentEntityType;
import com.rmgflow.document.service.CommercialDocumentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/documents")
@RequiredArgsConstructor
public class CommercialDocumentController {

    private final CommercialDocumentService commercialDocumentService;

    @GetMapping
    @PreAuthorize("hasAuthority('DOCUMENT_VIEW')")
    public List<CommercialDocumentResponse> list(@RequestParam DocumentEntityType entityType, @RequestParam Long entityId) {
        return commercialDocumentService.list(entityType, entityId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('DOCUMENT_MANAGE')")
    public ResponseEntity<CommercialDocumentResponse> upload(@Valid @RequestBody CommercialDocumentRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(commercialDocumentService.upload(request));
    }

    @PostMapping("/{id}/approve")
    @PreAuthorize("hasAuthority('DOCUMENT_MANAGE')")
    public CommercialDocumentResponse approve(@PathVariable Long id) {
        return commercialDocumentService.approve(id);
    }
}

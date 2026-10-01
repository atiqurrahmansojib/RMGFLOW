package com.rmgflow.style.controller;

import com.rmgflow.style.dto.StyleRevisionRequest;
import com.rmgflow.style.dto.StyleRevisionResponse;
import com.rmgflow.style.service.StyleRevisionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Document 7 (#31)/FR-31: no PUT/PATCH here by design — revisions are create-only. */
@RestController
@RequestMapping("/api/v1/styles/{styleId}/revisions")
@RequiredArgsConstructor
public class StyleRevisionController {

    private final StyleRevisionService styleRevisionService;

    @GetMapping
    @PreAuthorize("hasAuthority('STYLE_VIEW')")
    public List<StyleRevisionResponse> list(@PathVariable Long styleId) {
        return styleRevisionService.list(styleId);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('STYLE_MANAGE')")
    public ResponseEntity<StyleRevisionResponse> create(@PathVariable Long styleId, @RequestBody StyleRevisionRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(styleRevisionService.create(styleId, request));
    }
}

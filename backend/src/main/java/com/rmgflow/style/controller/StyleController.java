package com.rmgflow.style.controller;

import com.rmgflow.style.dto.StyleRequest;
import com.rmgflow.style.dto.StyleResponse;
import com.rmgflow.style.service.StyleService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/styles")
@RequiredArgsConstructor
public class StyleController {

    private final StyleService styleService;

    @GetMapping
    @PreAuthorize("hasAuthority('STYLE_VIEW')")
    public Page<StyleResponse> list(@RequestParam(required = false) String search, Pageable pageable) {
        return styleService.list(search, pageable);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('STYLE_VIEW')")
    public StyleResponse get(@PathVariable Long id) {
        return styleService.get(id);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('STYLE_MANAGE')")
    public ResponseEntity<StyleResponse> create(@Valid @RequestBody StyleRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(styleService.create(request));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('STYLE_MANAGE')")
    public StyleResponse update(@PathVariable Long id, @Valid @RequestBody StyleRequest request) {
        return styleService.update(id, request);
    }
}

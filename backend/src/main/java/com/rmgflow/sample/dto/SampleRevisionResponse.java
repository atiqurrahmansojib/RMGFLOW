package com.rmgflow.sample.dto;

import java.time.Instant;
import java.time.LocalDate;

public record SampleRevisionResponse(
        Long id, Long sampleId, int revisionNo, LocalDate submittedDate, String comments, Instant createdAt
) {
}

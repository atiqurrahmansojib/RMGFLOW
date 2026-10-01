package com.rmgflow.sample.dto;

import com.rmgflow.sample.entity.SampleStatus;

import java.time.LocalDate;

public record SampleResponse(
        Long id, String sampleNo, Long styleId, Long buyerId, Long factoryId, Long sampleTypeId,
        LocalDate requestDate, LocalDate requiredDate, SampleStatus currentStatus
) {
}

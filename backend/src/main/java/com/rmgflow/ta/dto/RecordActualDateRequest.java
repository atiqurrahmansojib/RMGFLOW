package com.rmgflow.ta.dto;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record RecordActualDateRequest(@NotNull LocalDate actualDate, String delayReason) {
}

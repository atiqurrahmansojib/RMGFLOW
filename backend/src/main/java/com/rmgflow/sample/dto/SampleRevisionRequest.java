package com.rmgflow.sample.dto;

import java.time.LocalDate;

public record SampleRevisionRequest(LocalDate submittedDate, String comments) {
}

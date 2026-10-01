package com.rmgflow.common;

import org.springframework.http.HttpStatus;

/** Document 11.3: typed business error mapped to a clean API error shape, never a raw 500. */
public class ApiException extends RuntimeException {

    private final HttpStatus status;

    public ApiException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}

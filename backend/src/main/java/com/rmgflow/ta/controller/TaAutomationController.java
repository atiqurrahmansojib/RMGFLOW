package com.rmgflow.ta.controller;

import com.rmgflow.ta.service.TaMilestoneOverdueScanService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Document 13 A2: manual trigger for the overdue-scan automation (also runs
 * daily via @Scheduled) — useful for an admin "run now" action and for tests
 * that shouldn't have to wait for a cron tick. */
@RestController
@RequestMapping("/api/v1/automation/ta-overdue-scan")
@RequiredArgsConstructor
public class TaAutomationController {

    private final TaMilestoneOverdueScanService taMilestoneOverdueScanService;

    @PostMapping
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public int runNow() {
        return taMilestoneOverdueScanService.run();
    }
}

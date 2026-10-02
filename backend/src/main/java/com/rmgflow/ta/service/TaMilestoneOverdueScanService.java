package com.rmgflow.ta.service;

import com.rmgflow.notification.service.NotificationService;
import com.rmgflow.ta.entity.TaMilestone;
import com.rmgflow.ta.repository.TaMilestoneRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

/**
 * Document 13 A2 ("T&A milestone overdue"): the first scheduled-job automation
 * wired end-to-end — Doc 9.5's derived OVERDUE status (TaMilestoneService) feeding
 * Doc 8.9's notification sink (NotificationService). Runs daily; also exposed as
 * run() for on-demand triggering (tests, an admin "run now" action) rather than
 * only being reachable via the cron schedule.
 *
 * Known simplification: no de-duplication — a milestone still overdue tomorrow
 * notifies again. Real de-dup (notify once per day, or only on state transitions
 * into OVERDUE) is Phase 13 polish, not done here; documented rather than silently
 * shipped as if it were complete.
 */
@Service
@RequiredArgsConstructor
public class TaMilestoneOverdueScanService {

    private final TaMilestoneRepository taMilestoneRepository;
    private final NotificationService notificationService;

    @Scheduled(cron = "0 0 7 * * *")
    @Transactional
    public void scheduledScan() {
        run();
    }

    @Transactional
    public int run() {
        LocalDate today = LocalDate.now();
        List<TaMilestone> candidates = taMilestoneRepository.findByActualDateIsNull();
        int notified = 0;
        for (TaMilestone milestone : candidates) {
            LocalDate effective = milestone.getEffectiveDate();
            if (effective.isBefore(today) && milestone.getResponsibleUser() != null) {
                notificationService.notify(milestone.getResponsibleUser().getId(), "TaMilestone", milestone.getId(),
                        "T&A milestone '" + milestone.getMilestoneType().getName() + "' for order "
                                + milestone.getOrder().getOrderNo() + " is overdue (was due " + effective + ")");
                notified++;
            }
        }
        return notified;
    }
}

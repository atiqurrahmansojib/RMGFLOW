package com.rmgflow.ta.entity;

/** Document 9.5: a convenience rollup recomputed from dates — never the source of
 * truth itself. Precedence when computing: DONE > BLOCKED > CRITICAL_DELAY >
 * OVERDUE > DUE_TODAY > UPCOMING > PENDING. */
public enum TaMilestoneStatus {
    PENDING, UPCOMING, DUE_TODAY, OVERDUE, CRITICAL_DELAY, BLOCKED, DONE
}

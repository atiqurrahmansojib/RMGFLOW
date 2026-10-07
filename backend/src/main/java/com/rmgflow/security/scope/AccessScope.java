package com.rmgflow.security.scope;

import java.util.Set;

/**
 * Document 5.1/5.2 "Scoped" + 5.3 object-level authorization: which buyers/factories
 * the current user may see beyond the tenant boundary. Shared by every list/get
 * endpoint and by reports (it replaces the report-only ReportScope).
 *
 * {@code unrestricted} (Super Admin, Owner, GM, Accounts, Management Viewer) sees the
 * whole organization. Everyone else is scoped by their {@code assignments} rows: a
 * record is visible when its buyer is in {@code buyerIds} OR one of its factories is
 * in {@code factoryIds}. Both sets are never null; both empty means "nothing", never
 * "everything". {@code buyerScoped} marks buyer-facing roles (merchandisers, sampling,
 * commercial), who keep the full factory directory for sourcing.
 */
public record AccessScope(boolean unrestricted, boolean buyerScoped, Set<Long> buyerIds, Set<Long> factoryIds) {

    public static final AccessScope UNRESTRICTED = new AccessScope(true, true, Set.of(), Set.of());

    /** JPQL {@code IN} needs a non-empty collection; this id never exists. */
    private static final Set<Long> NONE = Set.of(-1L);

    public AccessScope {
        buyerIds = buyerIds == null ? Set.of() : Set.copyOf(buyerIds);
        factoryIds = factoryIds == null ? Set.of() : Set.copyOf(factoryIds);
    }

    public static AccessScope scoped(boolean buyerScoped, Set<Long> buyerIds, Set<Long> factoryIds) {
        return new AccessScope(false, buyerScoped, buyerIds, factoryIds);
    }

    /** Buyer ids to bind to a JPQL {@code IN :buyerIds} (never empty). */
    public Set<Long> buyerIdsParam() {
        return buyerIds.isEmpty() ? NONE : buyerIds;
    }

    /** Factory ids to bind to a JPQL {@code IN :factoryIds} (never empty). */
    public Set<Long> factoryIdsParam() {
        return factoryIds.isEmpty() ? NONE : factoryIds;
    }

    /** Factory directory: open to unrestricted and buyer-facing roles, else assigned factories only. */
    public boolean allFactories() {
        return unrestricted || buyerScoped;
    }
}

-- Phase 5: standard sample type catalog (Document 9 §9 investigation list).
-- Buyer-specific types are added via the API (sample_types.buyer_id), not seeded here.

INSERT INTO sample_types (name, is_buyer_specific) VALUES
    ('Development Sample', FALSE),
    ('Proto Sample', FALSE),
    ('Fit Sample', FALSE),
    ('Size Set', FALSE),
    ('PP Sample', FALSE),
    ('TOP Sample', FALSE),
    ('Shipment Sample', FALSE);

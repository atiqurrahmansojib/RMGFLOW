-- Phase 2 (P2-T1, Document 8.2): reference/master data tables + seed values.
-- These are deliberately simple lookup tables (Super-Admin-managed) rather than
-- free text, per Doc 4.2 gap analysis (consistency for filtering/reporting).

CREATE TABLE currencies (
    code VARCHAR(3) PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE countries (
    code VARCHAR(2) PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE incoterms (
    code VARCHAR(3) PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE payment_terms (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    CONSTRAINT uq_payment_terms_name UNIQUE (name)
);

CREATE TABLE document_types (
    id                   BIGSERIAL PRIMARY KEY,
    name                 VARCHAR(150) NOT NULL,
    category             VARCHAR(50) NOT NULL,
    is_mandatory_default BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_document_types_name UNIQUE (name)
);

CREATE TABLE defect_types (
    id       BIGSERIAL PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    name     VARCHAR(150) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    CONSTRAINT chk_defect_types_severity CHECK (severity IN ('MINOR', 'MAJOR', 'CRITICAL')),
    CONSTRAINT uq_defect_types_name UNIQUE (name)
);

CREATE TABLE milestone_types (
    id                    BIGSERIAL PRIMARY KEY,
    name                  VARCHAR(150) NOT NULL,
    default_sequence      INT NOT NULL,
    typical_offset_days   INT,
    CONSTRAINT uq_milestone_types_name UNIQUE (name)
);

-- Seed data: a practical starting set, not exhaustive (Doc 3 FR-132 scope note —
-- document mandatoriness per destination/Incoterm still needs compliance input).

INSERT INTO currencies (code, name) VALUES
    ('USD', 'US Dollar'), ('EUR', 'Euro'), ('GBP', 'British Pound'),
    ('BDT', 'Bangladeshi Taka'), ('JPY', 'Japanese Yen'), ('CAD', 'Canadian Dollar');

INSERT INTO countries (code, name) VALUES
    ('BD', 'Bangladesh'), ('US', 'United States'), ('GB', 'United Kingdom'),
    ('DE', 'Germany'), ('FR', 'France'), ('ES', 'Spain'), ('IT', 'Italy'),
    ('CA', 'Canada'), ('JP', 'Japan'), ('CN', 'China'), ('IN', 'India'),
    ('NL', 'Netherlands'), ('SE', 'Sweden'), ('AU', 'Australia');

INSERT INTO incoterms (code, name) VALUES
    ('FOB', 'Free On Board'), ('CIF', 'Cost, Insurance and Freight'),
    ('EXW', 'Ex Works'), ('CFR', 'Cost and Freight'), ('DDP', 'Delivered Duty Paid'),
    ('FCA', 'Free Carrier');

INSERT INTO payment_terms (name, description) VALUES
    ('L/C AT SIGHT', 'Letter of Credit payable at sight'),
    ('L/C 30 DAYS', 'Letter of Credit payable 30 days after sight/shipment'),
    ('T/T IN ADVANCE', 'Telegraphic transfer in advance'),
    ('T/T AFTER SHIPMENT', 'Telegraphic transfer after shipment'),
    ('OPEN ACCOUNT 60 DAYS', 'Open account, 60 days from invoice');

INSERT INTO document_types (name, category, is_mandatory_default) VALUES
    ('Commercial Invoice', 'COMMERCIAL', TRUE),
    ('Packing List', 'COMMERCIAL', TRUE),
    ('Bill of Lading', 'SHIPMENT', TRUE),
    ('Airway Bill', 'SHIPMENT', FALSE),
    ('Certificate of Origin', 'COMPLIANCE', FALSE),
    ('Inspection Certificate', 'QUALITY', FALSE),
    ('Test Report', 'QUALITY', FALSE);

INSERT INTO defect_types (category, name, severity) VALUES
    ('STITCHING', 'Skip stitch', 'MAJOR'),
    ('STITCHING', 'Open seam', 'MAJOR'),
    ('FABRIC', 'Fabric hole', 'CRITICAL'),
    ('FABRIC', 'Shade variation', 'MAJOR'),
    ('MEASUREMENT', 'Out of tolerance', 'MAJOR'),
    ('APPEARANCE', 'Stain', 'MINOR'),
    ('TRIMS', 'Missing button', 'CRITICAL');

-- typical_offset_days = days BEFORE ex-factory date (Doc 8.7: planned_date =
-- ex_factory_date - offset_days_from_exfactory), so Ex-Factory itself is 0.
INSERT INTO milestone_types (name, default_sequence, typical_offset_days) VALUES
    ('Order Confirmation', 1, 90),
    ('Fabric Booking', 2, 85),
    ('Lab Dip Approval', 3, 70),
    ('Fabric In-House', 4, 60),
    ('Strike-off Approval', 5, 65),
    ('Trim Approval', 6, 55),
    ('PP Meeting', 7, 40),
    ('PP Sample Approval', 8, 35),
    ('Cutting', 9, 30),
    ('Sewing', 10, 20),
    ('Finishing', 11, 10),
    ('Final Inspection', 12, 5),
    ('Packing', 13, 3),
    ('Ex-Factory', 14, 0);

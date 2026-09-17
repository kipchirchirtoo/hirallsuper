-- ==============================================================================
-- 00100_kenya_compliance_etims_mpesa.sql
-- KRA eTIMS (OSCU & Offline VSCU) and Safaricom Daraja 3.0 M-Pesa Native Integrations
-- ==============================================================================

-- 1. KRA eTIMS Electronic Tax Invoices
CREATE TABLE IF NOT EXISTS etims_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id) ON DELETE SET NULL,
    sale_id UUID REFERENCES sales(id) ON DELETE SET NULL,
    
    -- Official KRA Invoicing Identifiers
    invoice_number VARCHAR(100) NOT NULL, -- e.g. 'KRA-B01-2026-00004523'
    control_unit_id VARCHAR(64) NOT NULL,  -- e.g. KRA Control Unit Serial Number
    internal_sequence BIGINT NOT NULL,     -- Monotonically increasing sequence
    taxpayer_pin VARCHAR(50) NOT NULL,     -- Enterprise KRA PIN
    customer_pin VARCHAR(50),              -- Buyer PIN (required for B2B or input VAT claiming)
    
    -- Tax Breakdown
    taxable_amount_a_16 NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    tax_amount_a_16 NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    zero_rated_amount_b NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    exempt_amount_c NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    fuel_taxable_amount_e NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    fuel_tax_amount_e NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    total_invoice_amount NUMERIC(12, 4) NOT NULL,
    
    -- Cryptographic Signature & Verification QR Code
    signature_data VARCHAR(512) NOT NULL,
    qr_code_url VARCHAR(1024) NOT NULL, -- Official URL scanned by KRA verification app
    
    -- Transmission & Offline VSCU Sync Status
    transmission_mode VARCHAR(32) NOT NULL DEFAULT 'VSCU_OFFLINE', -- 'OSCU_ONLINE', 'VSCU_OFFLINE'
    status VARCHAR(32) NOT NULL DEFAULT 'SIGNED_LOCAL', 
    -- 'SIGNED_LOCAL', 'TRANSMITTED_TO_KRA', 'ACCEPTED_BY_KRA', 'REJECTED_BY_KRA', 'RETRY_QUEUE'
    kra_acknowledgement_receipt VARCHAR(128),
    last_transmission_attempt TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_etims_invoice_num UNIQUE (organization_id, invoice_number)
);

CREATE INDEX IF NOT EXISTS idx_etims_status ON etims_invoices(status, created_at DESC);

-- 2. Safaricom Daraja M-Pesa Transactions
CREATE TABLE IF NOT EXISTS mpesa_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    sale_id UUID REFERENCES sales(id) ON DELETE SET NULL,
    
    transaction_type VARCHAR(32) NOT NULL DEFAULT 'STK_PUSH', 
    -- 'STK_PUSH' (Lipa na M-Pesa Online), 'C2B_TILL', 'C2B_PAYBILL', 'B2C_REFUND'
    merchant_request_id VARCHAR(128) NOT NULL,
    checkout_request_id VARCHAR(128) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,     -- Customer phone (2547XXXXXXXX)
    amount NUMERIC(12, 4) NOT NULL,
    
    -- Callback Receipt Data
    mpesa_receipt_number VARCHAR(64),      -- e.g. 'QHX8291A0K'
    result_code INT,                       -- 0 = Success, 1032 = Cancelled by user, etc.
    result_desc TEXT,
    transaction_date TIMESTAMPTZ,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'COMPLETED', 'FAILED', 'CANCELLED'
    
    raw_callback_payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_mpesa_checkout UNIQUE (checkout_request_id)
);

CREATE INDEX IF NOT EXISTS idx_mpesa_receipt ON mpesa_transactions(mpesa_receipt_number);
CREATE INDEX IF NOT EXISTS idx_mpesa_status ON mpesa_transactions(status);

-- ==============================================================================
-- 00060_retail_pos_and_cash_office.sql
-- Supermarket Retail POS, Cashier Shifts, Cash Office Safe Management & Sales Audit
-- ==============================================================================

-- 1. POS Terminals
CREATE TABLE IF NOT EXISTS pos_terminals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    terminal_code VARCHAR(64) NOT NULL,
    name VARCHAR(128) NOT NULL,
    device_id UUID REFERENCES devices(id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_branch_term UNIQUE (branch_id, terminal_code)
);

-- 2. Cashier Shifts (Float, Cash Drops, Counting & X/Z Reports)
CREATE TABLE IF NOT EXISTS cashier_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    pos_terminal_id UUID NOT NULL REFERENCES pos_terminals(id),
    cashier_user_id UUID NOT NULL REFERENCES users(id),
    shift_number VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'OPEN', -- 'OPEN', 'CLOSED', 'AUDITED'
    
    opening_float NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    total_sales_cash NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    total_sales_mpesa NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    total_sales_card NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    total_cash_drops NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    total_paid_outs NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    
    expected_cash_in_drawer NUMERIC(12, 4),
    actual_cash_counted NUMERIC(12, 4),
    cash_variance NUMERIC(12, 4), -- Shortage (negative) or Overage (positive)
    
    opened_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMPTZ,
    audited_by UUID REFERENCES users(id) ON DELETE SET NULL,
    z_report_payload JSONB
);

CREATE INDEX IF NOT EXISTS idx_cashier_shifts_status ON cashier_shifts(branch_id, status);

-- 3. Cash Drops to Cash Office / Safe
CREATE TABLE IF NOT EXISTS cash_drops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    shift_id UUID NOT NULL REFERENCES cashier_shifts(id) ON DELETE CASCADE,
    cashier_user_id UUID NOT NULL REFERENCES users(id),
    amount NUMERIC(12, 4) NOT NULL,
    received_in_cash_office_by UUID REFERENCES users(id) ON DELETE SET NULL,
    verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Sales & Invoices
CREATE TABLE IF NOT EXISTS sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_sale_id UUID NOT NULL, -- Permanent UUID from SQLite for offline idempotency
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    pos_terminal_id UUID REFERENCES pos_terminals(id),
    shift_id UUID REFERENCES cashier_shifts(id),
    cashier_user_id UUID REFERENCES users(id),
    sale_number VARCHAR(64) NOT NULL,
    subtotal NUMERIC(12, 4) NOT NULL,
    tax_total NUMERIC(12, 4) NOT NULL,
    discount_total NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    grand_total NUMERIC(12, 4) NOT NULL,
    payment_status VARCHAR(32) NOT NULL DEFAULT 'PAID', -- 'PAID', 'PARTIAL', 'REFUNDED', 'VOIDED'
    sale_type VARCHAR(32) NOT NULL DEFAULT 'RETAIL',    -- 'RETAIL', 'RESTAURANT', 'BAR', 'WHOLESALE'
    etims_invoice_number VARCHAR(100),                 -- KRA eTIMS invoice number
    offline_created_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sale_client UNIQUE (organization_id, client_sale_id)
);

CREATE INDEX IF NOT EXISTS idx_sales_query ON sales(branch_id, created_at DESC);

-- 5. Sale Items
CREATE TABLE IF NOT EXISTS sale_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    sku VARCHAR(64) NOT NULL,
    quantity NUMERIC(12, 4) NOT NULL,
    unit_price NUMERIC(12, 4) NOT NULL,
    tax_rate NUMERIC(6, 4) NOT NULL DEFAULT 0.1600,
    tax_amount NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    discount_amount NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    total_amount NUMERIC(12, 4) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 6. Multi-Tender Payments
CREATE TABLE IF NOT EXISTS sale_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    payment_method VARCHAR(32) NOT NULL, -- 'CASH', 'MPESA', 'CARD', 'CREDIT', 'VOUCHER'
    amount NUMERIC(12, 4) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'KES',
    reference VARCHAR(128),              -- M-Pesa Code (e.g. QHX123) or Card Auth code
    change_given NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 7. Sales Audit & Loss Prevention Exception Detection
CREATE TABLE IF NOT EXISTS sales_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    sale_id UUID REFERENCES sales(id) ON DELETE SET NULL,
    cashier_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    exception_type VARCHAR(64) NOT NULL, 
    -- 'VOID_ITEM', 'VOID_SALE', 'PRICE_OVERRIDE', 'EXCESSIVE_DISCOUNT', 'DRAWER_OPEN_NO_SALE', 'CASH_SHORTAGE'
    severity VARCHAR(16) NOT NULL DEFAULT 'MEDIUM', -- 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    amount NUMERIC(12, 4),
    reason TEXT,
    supervisor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sales_audit_branch ON sales_audit(branch_id, severity, created_at DESC);

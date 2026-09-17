-- ==============================================================================
-- 00080_customers_crm_and_credit.sql
-- Customer Profiles, Membership Loyalty Points & Store Credit Accounts with Aging
-- ==============================================================================

-- 1. Customers Master
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    code VARCHAR(64) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(255),
    national_id VARCHAR(50),
    tax_pin VARCHAR(50), -- KRA PIN if corporate buyer
    membership_tier VARCHAR(32) NOT NULL DEFAULT 'BRONZE', -- 'BRONZE', 'SILVER', 'GOLD', 'PLATINUM'
    loyalty_points_balance INT NOT NULL DEFAULT 0,
    total_spend NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_phone UNIQUE (organization_id, phone)
);

CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(organization_id, phone);

-- 2. Customer Credit Accounts (For Accounts Receivable & Aging 30/60/90 days)
CREATE TABLE IF NOT EXISTS customer_credit_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    credit_limit NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    current_balance NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    aging_current NUMERIC(12, 4) NOT NULL DEFAULT 0.0000, -- 0-30 days
    aging_30_days NUMERIC(12, 4) NOT NULL DEFAULT 0.0000, -- 31-60 days
    aging_60_days NUMERIC(12, 4) NOT NULL DEFAULT 0.0000, -- 61-90 days
    aging_90_plus NUMERIC(12, 4) NOT NULL DEFAULT 0.0000, -- 90+ days
    payment_terms VARCHAR(32) NOT NULL DEFAULT 'NET_30',
    is_frozen BOOLEAN NOT NULL DEFAULT false,
    approved_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_credit UNIQUE (customer_id)
);

-- 3. Loyalty Transactions Ledger
CREATE TABLE IF NOT EXISTS loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    sale_id UUID REFERENCES sales(id) ON DELETE SET NULL,
    transaction_type VARCHAR(16) NOT NULL, -- 'EARN', 'REDEEM', 'ADJUST'
    points INT NOT NULL,
    balance_after INT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

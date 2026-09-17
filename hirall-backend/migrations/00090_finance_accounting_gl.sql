-- ==============================================================================
-- 00090_finance_accounting_gl.sql
-- Chart of Accounts, Double-Entry General Ledger, AP, AR & Petty Cash
-- ==============================================================================

-- 1. Chart of Accounts (COA)
CREATE TABLE IF NOT EXISTS chart_of_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    account_code VARCHAR(32) NOT NULL, -- e.g. 1010, 2010, 4010, 5010
    account_name VARCHAR(150) NOT NULL,
    account_type VARCHAR(32) NOT NULL, -- 'ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'COGS', 'EXPENSE'
    parent_account_id UUID REFERENCES chart_of_accounts(id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_account_org_code UNIQUE (organization_id, account_code)
);

CREATE INDEX IF NOT EXISTS idx_coa_type ON chart_of_accounts(organization_id, account_type);

-- 2. General Ledger Journal Entries
CREATE TABLE IF NOT EXISTS journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    entry_number VARCHAR(64) NOT NULL,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    reference_type VARCHAR(64), -- 'POS_DAILY_SALES', 'SUPPLIER_INVOICE', 'PAYROLL', 'EXPENSE'
    reference_id UUID,
    description TEXT NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'POSTED', -- 'DRAFT', 'POSTED', 'VOIDED'
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_journal_num UNIQUE (organization_id, entry_number)
);

CREATE TABLE IF NOT EXISTS journal_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_entry_id UUID NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    cost_center_id UUID REFERENCES cost_centers(id) ON DELETE SET NULL,
    debit NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    credit NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    memo TEXT
);

CREATE INDEX IF NOT EXISTS idx_journal_lines_acc ON journal_lines(account_id);

-- 3. Accounts Payable (AP - Supplier Invoices & Payments)
CREATE TABLE IF NOT EXISTS accounts_payable (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES suppliers(id),
    po_id UUID REFERENCES purchase_orders(id) ON DELETE SET NULL,
    invoice_number VARCHAR(100) NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    amount NUMERIC(12, 4) NOT NULL,
    amount_paid NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    status VARCHAR(32) NOT NULL DEFAULT 'UNPAID', -- 'UNPAID', 'PARTIALLY_PAID', 'PAID'
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Petty Cash Funds & Branch Expenses
CREATE TABLE IF NOT EXISTS petty_cash_funds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    fund_name VARCHAR(100) NOT NULL,
    custodian_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    imprest_amount NUMERIC(12, 4) NOT NULL DEFAULT 10000.0000, -- Float balance in KES
    current_cash_balance NUMERIC(12, 4) NOT NULL DEFAULT 10000.0000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS branch_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    fund_id UUID REFERENCES petty_cash_funds(id) ON DELETE SET NULL,
    expense_category VARCHAR(64) NOT NULL, 
    -- 'UTILITIES_ELECTRICITY', 'UTILITIES_WATER', 'CLEANING', 'REPAIRS', 'FUEL', 'TRANSPORT', 'OFFICE_SUPPLIES'
    amount NUMERIC(12, 4) NOT NULL,
    payee VARCHAR(255) NOT NULL,
    receipt_attachment_url VARCHAR(1024),
    paid_by UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'APPROVED', -- 'PENDING', 'APPROVED', 'REJECTED'
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

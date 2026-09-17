-- ==============================================================================
-- 00030_inventory_ledger_and_batches.sql
-- Multi-Location Stock Balances, Immutable Movement Ledger, Batches & FEFO Expiry
-- ==============================================================================

-- 1. Batches & Expiry (First Expiry, First Out - FEFO tracking)
CREATE TABLE IF NOT EXISTS batches_expiry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    batch_number VARCHAR(100) NOT NULL,
    manufacture_date DATE,
    expiry_date DATE NOT NULL,
    received_date DATE NOT NULL DEFAULT CURRENT_DATE,
    supplier_id UUID, -- References suppliers(id)
    initial_quantity NUMERIC(12, 4) NOT NULL,
    current_quantity NUMERIC(12, 4) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, EXPIRED, QUARANTINED
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_batch UNIQUE (product_id, batch_number)
);

CREATE INDEX IF NOT EXISTS idx_batches_fefo ON batches_expiry(product_id, expiry_date ASC);

-- 2. Stock Balances per Branch and Physical Location
CREATE TABLE IF NOT EXISTS stock_balances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES batches_expiry(id) ON DELETE SET NULL,
    location_area VARCHAR(64) NOT NULL DEFAULT 'SHOP_FLOOR', 
    -- 'SHOP_FLOOR', 'BACK_STORE', 'KITCHEN_STORE', 'BAR_STORE', 'CENTRAL_WAREHOUSE'
    quantity NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    reserved_quantity NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    min_level NUMERIC(12, 4) DEFAULT 10.0000,
    max_level NUMERIC(12, 4) DEFAULT 100.0000,
    reorder_point NUMERIC(12, 4) DEFAULT 20.0000,
    safety_stock NUMERIC(12, 4) DEFAULT 15.0000,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_stock_location UNIQUE (branch_id, product_id, location_area)
);

CREATE INDEX IF NOT EXISTS idx_stock_balances_lookup ON stock_balances(branch_id, product_id, location_area);

-- 3. Stock Movements (Immutable Enterprise Stock Ledger)
CREATE TABLE IF NOT EXISTS stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES batches_expiry(id) ON DELETE SET NULL,
    location_area VARCHAR(64) NOT NULL DEFAULT 'SHOP_FLOOR',
    movement_type VARCHAR(32) NOT NULL,
    -- 'PURCHASE', 'SALE', 'RETURN', 'TRANSFER_IN', 'TRANSFER_OUT', 'ADJUSTMENT',
    -- 'BREAKAGE', 'LOSS', 'OPENING', 'STOCK_COUNT', 'RECIPE_CONSUMPTION', 'PRODUCTION_OUTPUT'
    quantity NUMERIC(12, 4) NOT NULL, -- Positive for in, negative for out
    balance_after NUMERIC(12, 4) NOT NULL,
    unit_cost NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    total_cost NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    reference_type VARCHAR(64), -- 'SALE', 'GRN', 'TRANSFER', 'WASTAGE', 'RECIPE_ORDER'
    reference_id UUID,
    device_id UUID REFERENCES devices(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_stock_movements_history ON stock_movements(branch_id, product_id, created_at DESC);

-- 4. Wastage, Shrinkage & Spoilage Auditing
CREATE TABLE IF NOT EXISTS wastage_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES batches_expiry(id) ON DELETE SET NULL,
    quantity NUMERIC(12, 4) NOT NULL,
    unit_cost NUMERIC(12, 4) NOT NULL,
    total_loss NUMERIC(12, 4) NOT NULL,
    reason VARCHAR(64) NOT NULL, 
    -- 'EXPIRY', 'SPOILAGE', 'THEFT', 'LEAKAGE', 'DAMAGE', 'PRODUCTION_WASTE'
    reported_by UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    evidence_photo_url VARCHAR(1024),
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING_APPROVAL', -- 'PENDING_APPROVAL', 'APPROVED', 'REJECTED'
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_wastage_branch ON wastage_records(branch_id, created_at DESC);

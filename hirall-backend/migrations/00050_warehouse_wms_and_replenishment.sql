-- ==============================================================================
-- 00050_warehouse_wms_and_replenishment.sql
-- WMS Bins, Put-away, Wave Picking, Dispatch Fleet Tracking & Auto-Replenishment
-- ==============================================================================

-- 1. Warehouses Master (Central DC vs Branch Storage)
CREATE TABLE IF NOT EXISTS warehouses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL, -- Optional link to a branch
    code VARCHAR(64) NOT NULL,
    name VARCHAR(255) NOT NULL,
    is_central_dc BOOLEAN NOT NULL DEFAULT false,
    address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_warehouse_code UNIQUE (organization_id, code)
);

-- 2. Warehouse Locations & Bins (Zone-Aisle-Rack-Shelf-Bin)
CREATE TABLE IF NOT EXISTS warehouse_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    code VARCHAR(64) NOT NULL, -- E.g. 'A-01-02-B'
    zone VARCHAR(64) NOT NULL, -- 'ZONE_A', 'ZONE_B', 'COLD_ROOM', 'FREEZER', 'BULK_STORAGE'
    aisle VARCHAR(32),
    rack VARCHAR(32),
    shelf VARCHAR(32),
    bin VARCHAR(32),
    temperature_type VARCHAR(32) NOT NULL DEFAULT 'AMBIENT', -- 'AMBIENT', 'CHILLED', 'FROZEN'
    max_capacity_kg NUMERIC(10, 2),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_warehouse_bin_code UNIQUE (warehouse_id, code)
);

CREATE INDEX IF NOT EXISTS idx_wh_locations ON warehouse_locations(warehouse_id, zone, code);

-- 3. Inter-Branch Transfers & Central DC Replenishment Orders
CREATE TABLE IF NOT EXISTS inter_branch_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    transfer_number VARCHAR(64) NOT NULL,
    from_branch_id UUID NOT NULL REFERENCES branches(id),
    to_branch_id UUID NOT NULL REFERENCES branches(id),
    from_warehouse_id UUID REFERENCES warehouses(id),
    to_warehouse_id UUID REFERENCES warehouses(id),
    status VARCHAR(32) NOT NULL DEFAULT 'REQUESTED',
    -- 'DRAFT', 'REQUESTED', 'APPROVED', 'PICKING', 'PACKED', 'DISPATCHED', 'IN_TRANSIT', 'RECEIVED', 'CANCELLED'
    priority VARCHAR(16) NOT NULL DEFAULT 'NORMAL', -- 'LOW', 'NORMAL', 'URGENT'
    driver_name VARCHAR(100),
    vehicle_registration VARCHAR(50),
    dispatched_at TIMESTAMPTZ,
    received_at TIMESTAMPTZ,
    created_by UUID REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_transfer_num UNIQUE (organization_id, transfer_number)
);

CREATE TABLE IF NOT EXISTS transfer_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_id UUID NOT NULL REFERENCES inter_branch_transfers(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity_requested NUMERIC(12, 4) NOT NULL,
    quantity_picked NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    quantity_dispatched NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    quantity_received NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    unit_cost NUMERIC(12, 4) NOT NULL DEFAULT 0.0000
);

-- 4. Branch Replenishment Engine Configuration
CREATE TABLE IF NOT EXISTS replenishment_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    min_stock_level NUMERIC(12, 4) NOT NULL,
    max_stock_level NUMERIC(12, 4) NOT NULL,
    safety_stock NUMERIC(12, 4) NOT NULL DEFAULT 10.0000,
    reorder_point NUMERIC(12, 4) NOT NULL,
    lead_time_days INT NOT NULL DEFAULT 2,
    is_auto_replenish BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_branch_product_replenishment UNIQUE (branch_id, product_id)
);

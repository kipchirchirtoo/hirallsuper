-- ==============================================================================
-- GIFTMART SUPERMARKET: CONSOLIDATED DATABASE SCHEMA AND SEED
-- Generated on 2026-09-05 21:01:01
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Migration: 00010_enterprise_and_identity.sql
-- ------------------------------------------------------------------------------
-- ==============================================================================
-- 00010_enterprise_and_identity.sql
-- HIRALL Enterprise Hierarchy: Organizations, Branches, Departments, Cost Centers,
-- Hardware Devices, Granular Permissions & Multi-Branch Scoped Users
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Organizations (Top-level Enterprise Entity)
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(64) UNIQUE NOT NULL,
    legal_name VARCHAR(255),
    registration_number VARCHAR(100),
    tax_pin VARCHAR(50) NOT NULL, -- E.g. KRA PIN (P051234567Z)
    vat_status VARCHAR(32) NOT NULL DEFAULT 'REGISTERED', -- REGISTERED, EXEMPT, TURNOVER_TAX
    currency VARCHAR(10) NOT NULL DEFAULT 'KES',
    fiscal_year_start INT NOT NULL DEFAULT 1, -- Month (1 = January)
    timezone VARCHAR(64) NOT NULL DEFAULT 'Africa/Nairobi',
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    logo_url VARCHAR(1024),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_organizations_code ON organizations(code);
CREATE INDEX IF NOT EXISTS idx_organizations_tax_pin ON organizations(tax_pin);

-- 2. Branches (Operational Units: Supermarkets, Central Warehouse, Distribution Hubs)
CREATE TABLE IF NOT EXISTS branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(64) NOT NULL,
    branch_type VARCHAR(64) NOT NULL DEFAULT 'HYBRID_RETAIL_RESTAURANT', 
    -- 'SUPERMARKET_ONLY', 'CENTRAL_WAREHOUSE', 'RESTAURANT_BAR_ONLY', 'HYBRID_RETAIL_RESTAURANT'
    manager_name VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    address TEXT,
    city VARCHAR(100) NOT NULL DEFAULT 'Nairobi',
    country VARCHAR(100) NOT NULL DEFAULT 'Kenya',
    etims_branch_code VARCHAR(32) DEFAULT '00', -- KRA eTIMS branch code (00 = Head Office / Main)
    operating_hours JSONB,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_branch_org_code UNIQUE (organization_id, code)
);

CREATE INDEX IF NOT EXISTS idx_branches_org_type ON branches(organization_id, branch_type);

-- 3. Departments & Cost Centers
CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(32) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cost_centers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(32) NOT NULL,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Hardware Devices (POS Registers, Tablets, KDS, Scanners)
CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    device_uuid VARCHAR(128) NOT NULL, -- Permanent hardware UUID
    device_name VARCHAR(128) NOT NULL,
    device_mode VARCHAR(64) NOT NULL DEFAULT 'RETAIL_POS', 
    -- 'RETAIL_POS', 'RESTAURANT_POS', 'KITCHEN_DISPLAY', 'BAR_STATION', 'WAREHOUSE_SCANNER', 'CASH_OFFICE'
    platform VARCHAR(32) NOT NULL DEFAULT 'WINDOWS', -- 'WINDOWS', 'LINUX', 'ANDROID'
    app_version VARCHAR(32) NOT NULL DEFAULT '1.0.0',
    etims_vscu_sequence BIGINT NOT NULL DEFAULT 1, -- Offline sequential invoice counter
    last_seen_at TIMESTAMPTZ,
    sync_status VARCHAR(32) NOT NULL DEFAULT 'ONLINE',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_device_org_uuid UNIQUE (organization_id, device_uuid)
);

CREATE INDEX IF NOT EXISTS idx_devices_branch_mode ON devices(branch_id, device_mode);

-- 5. Users & Identity
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    pin_code VARCHAR(128), -- Hashed 4-6 digit quick login PIN for cashiers/waiters
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_org_email UNIQUE (organization_id, email)
);

CREATE INDEX IF NOT EXISTS idx_users_org_email ON users(organization_id, email);

-- 6. Granular Permissions & Role-Based Access Control
CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(100) UNIQUE NOT NULL, -- e.g. 'sales.void', 'wms.dispatch', 'kitchen.view'
    category VARCHAR(64) NOT NULL,     -- POS, WMS, RESTAURANT, BAR, FINANCE, HR, ADMIN
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_system BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_role_org_name UNIQUE (organization_id, name)
);

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE, -- NULL = Enterprise-wide
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_role_branch_assignment UNIQUE (user_id, role_id, branch_id)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_lookup ON user_roles(user_id, branch_id);


-- ------------------------------------------------------------------------------
-- Migration: 00020_catalog_pricing_promotions.sql
-- ------------------------------------------------------------------------------
-- ==============================================================================
-- 00020_catalog_pricing_promotions.sql
-- Merchandising, Enterprise Product Master, Dynamic Pricing Engine & Promotions
-- ==============================================================================

-- 1. Merchandising Categories (Multi-level Tree)
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(64) NOT NULL,
    department VARCHAR(64) NOT NULL DEFAULT 'RETAIL', -- 'RETAIL', 'FRESH_FOOD', 'BAKERY', 'RESTAURANT', 'BAR'
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_categories_org_dept ON categories(organization_id, department);

-- 2. Brands & Units
CREATE TABLE IF NOT EXISTS brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(64) NOT NULL,
    code VARCHAR(16) NOT NULL, -- PCS, KG, G, L, ML, BOTTLE, PACK
    precision INT NOT NULL DEFAULT 0
);

-- 3. Products Master (Supermarket, Kitchen Raw Materials, Recipes & Bar)
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    sku VARCHAR(64) NOT NULL,
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(64),
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    brand_id UUID REFERENCES brands(id) ON DELETE SET NULL,
    unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
    cost_price NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    selling_price NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    wholesale_price NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    
    -- Kenya KRA eTIMS Tax Parameters
    tax_category VARCHAR(32) NOT NULL DEFAULT 'A_STANDARD_16', 
    -- 'A_STANDARD_16' (16%), 'B_ZERO_RATED_0' (0%), 'C_EXEMPT', 'E_FUEL_8' (8%)
    tax_rate NUMERIC(6, 4) NOT NULL DEFAULT 0.1600,
    etims_item_code VARCHAR(64), -- Official KRA Classification code (HS Code)
    
    -- Operational Flags
    is_supermarket_item BOOLEAN NOT NULL DEFAULT true,
    is_restaurant_menu BOOLEAN NOT NULL DEFAULT false, -- Prepared dish (has recipe/BOM)
    is_kitchen_raw_material BOOLEAN NOT NULL DEFAULT false, -- Ingredient (beef, cheese, flour)
    is_bar_item BOOLEAN NOT NULL DEFAULT false,        -- Bar beverage or liquor bottle
    bottle_volume_ml NUMERIC(8, 2),                   -- If liquor bottle (e.g. 750ml, 1000ml)
    standard_pour_ml NUMERIC(8, 2),                   -- Standard tot / shot (e.g. 30ml, 50ml)

    track_stock BOOLEAN NOT NULL DEFAULT true,
    allow_negative_stock BOOLEAN NOT NULL DEFAULT false,
    min_stock_alert NUMERIC(12, 4) DEFAULT 10.0000,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_org_sku UNIQUE (organization_id, sku)
);

CREATE INDEX IF NOT EXISTS idx_products_sku ON products(organization_id, sku);
CREATE INDEX IF NOT EXISTS idx_products_tax_cat ON products(tax_category);

-- 4. Barcodes (Multiple barcodes: primary EAN-13, inner carton, outer box)
CREATE TABLE IF NOT EXISTS product_barcodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    barcode VARCHAR(128) NOT NULL,
    barcode_type VARCHAR(32) NOT NULL DEFAULT 'EAN13',
    conversion_factor NUMERIC(10, 4) NOT NULL DEFAULT 1.0000, -- e.g. Pack of 6 has factor 6.0
    is_primary BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_barcode UNIQUE (product_id, barcode)
);

CREATE INDEX IF NOT EXISTS idx_barcodes_lookup ON product_barcodes(barcode);

-- 5. Dynamic Pricing Engine Rules (Branch-specific, Volume tiers, Clearance)
CREATE TABLE IF NOT EXISTS pricing_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE, -- NULL = All branches
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    price_type VARCHAR(32) NOT NULL DEFAULT 'BRANCH_OVERRIDE', 
    -- 'BRANCH_OVERRIDE', 'WHOLESALE_TIER', 'MEMBER_PRICE', 'CLEARANCE'
    min_quantity NUMERIC(12, 4) NOT NULL DEFAULT 1.0000,
    fixed_price NUMERIC(12, 4),
    discount_percentage NUMERIC(6, 4),
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 6. Promotions Engine (BOGO, Combos, Happy Hours)
CREATE TABLE IF NOT EXISTS promotions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE, -- NULL = All
    name VARCHAR(255) NOT NULL,
    promo_type VARCHAR(32) NOT NULL, 
    -- 'BUY_X_GET_Y', 'PERCENT_DISCOUNT', 'COMBO_BUNDLE', 'HAPPY_HOUR'
    conditions JSONB NOT NULL, 
    -- e.g. {"buy_product_id": "...", "buy_qty": 2, "get_product_id": "...", "get_qty": 1, "discount_pct": 1.0}
    time_start TIME, -- For Happy Hours (e.g. 17:00 to 20:00)
    time_end TIME,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_promotions_active ON promotions(organization_id, is_active, start_date, end_date);


-- ------------------------------------------------------------------------------
-- Migration: 00030_inventory_ledger_and_batches.sql
-- ------------------------------------------------------------------------------
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


-- ------------------------------------------------------------------------------
-- Migration: 00040_procurement_and_receiving.sql
-- ------------------------------------------------------------------------------
-- ==============================================================================
-- 00040_procurement_and_receiving.sql
-- Supplier Directory, Purchase Orders, Goods Received Notes (GRN) & 3-Way Match
-- ==============================================================================

-- 1. Suppliers Master
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    code VARCHAR(64) NOT NULL,
    name VARCHAR(255) NOT NULL,
    tax_pin VARCHAR(50), -- KRA PIN
    contact_person VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(255),
    address TEXT,
    payment_terms VARCHAR(64) NOT NULL DEFAULT 'NET_30', -- 'COD', 'NET_15', 'NET_30', 'NET_60'
    credit_limit NUMERIC(12, 4) DEFAULT 0.0000,
    lead_time_days INT NOT NULL DEFAULT 3,
    delivery_accuracy_score NUMERIC(5, 2) DEFAULT 100.00, -- Dynamic KPI
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_supplier_code UNIQUE (organization_id, code)
);

CREATE INDEX IF NOT EXISTS idx_suppliers_org ON suppliers(organization_id);

-- 2. Purchase Orders
CREATE TABLE IF NOT EXISTS purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE, -- Destination branch or central DC
    supplier_id UUID NOT NULL REFERENCES suppliers(id),
    po_number VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'DRAFT', 
    -- 'DRAFT', 'SUBMITTED', 'APPROVED', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED'
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_delivery_date DATE,
    subtotal NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    tax_total NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    grand_total NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    notes TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_po_number UNIQUE (organization_id, po_number)
);

CREATE TABLE IF NOT EXISTS purchase_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    po_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity_ordered NUMERIC(12, 4) NOT NULL,
    quantity_received NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    unit_cost NUMERIC(12, 4) NOT NULL,
    tax_rate NUMERIC(6, 4) NOT NULL DEFAULT 0.1600,
    total_cost NUMERIC(12, 4) NOT NULL
);

-- 3. Goods Received Notes (GRN - Receiving Dock Dock-to-Stock)
CREATE TABLE IF NOT EXISTS goods_received_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    po_id UUID REFERENCES purchase_orders(id) ON DELETE SET NULL,
    supplier_id UUID NOT NULL REFERENCES suppliers(id),
    grn_number VARCHAR(64) NOT NULL,
    supplier_delivery_note VARCHAR(100),
    supplier_invoice_number VARCHAR(100),
    status VARCHAR(32) NOT NULL DEFAULT 'COMPLETED', -- 'IN_PROGRESS', 'COMPLETED', 'DISCREPANCY'
    total_received_cost NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    received_by UUID REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_grn_number UNIQUE (organization_id, grn_number)
);

CREATE TABLE IF NOT EXISTS grn_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grn_id UUID NOT NULL REFERENCES goods_received_notes(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    batch_number VARCHAR(100),
    expiry_date DATE,
    quantity_expected NUMERIC(12, 4) NOT NULL,
    quantity_received NUMERIC(12, 4) NOT NULL,
    quantity_damaged NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    unit_cost NUMERIC(12, 4) NOT NULL,
    total_cost NUMERIC(12, 4) NOT NULL
);


-- ------------------------------------------------------------------------------
-- Migration: 00050_warehouse_wms_and_replenishment.sql
-- ------------------------------------------------------------------------------
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


-- ------------------------------------------------------------------------------
-- Migration: 00060_retail_pos_and_cash_office.sql
-- ------------------------------------------------------------------------------
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


-- ------------------------------------------------------------------------------
-- Migration: 00070_hospitality_restaurant_bar.sql
-- ------------------------------------------------------------------------------
-- ==============================================================================
-- 00070_hospitality_restaurant_bar.sql
-- Restaurant Table Floor Plan, Dining Orders, Kitchen KDS, Recipes/BOM & Bar Pour Tracking
-- ==============================================================================

-- 1. Restaurant Floors & Tables
CREATE TABLE IF NOT EXISTS restaurant_floors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL, -- E.g. 'Main Dining', 'Terrace', 'VIP Lounge', 'Bar Section'
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS restaurant_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    floor_id UUID NOT NULL REFERENCES restaurant_floors(id) ON DELETE CASCADE,
    table_number VARCHAR(32) NOT NULL,
    capacity INT NOT NULL DEFAULT 4,
    status VARCHAR(32) NOT NULL DEFAULT 'AVAILABLE',
    -- 'AVAILABLE', 'OCCUPIED', 'ORDERED', 'PREPARING', 'READY', 'BILL_REQUESTED', 'PAID', 'RESERVED'
    current_order_id UUID,
    pos_x INT NOT NULL DEFAULT 0, -- Graphical 2D floor plan coordinates
    pos_y INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_floor_table_num UNIQUE (floor_id, table_number)
);

CREATE INDEX IF NOT EXISTS idx_tables_status ON restaurant_tables(floor_id, status);

-- 2. Dining Orders (Hospitality Checks / Tabs)
CREATE TABLE IF NOT EXISTS dining_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_order_id UUID NOT NULL,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    table_id UUID REFERENCES restaurant_tables(id) ON DELETE SET NULL,
    order_number VARCHAR(64) NOT NULL,
    waiter_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    guests_count INT NOT NULL DEFAULT 1,
    status VARCHAR(32) NOT NULL DEFAULT 'OPEN', -- 'OPEN', 'KITCHEN_SENT', 'SERVED', 'BILLED', 'PAID', 'VOIDED'
    subtotal NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    service_charge NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    tax_total NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    grand_total NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dining_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES dining_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    quantity NUMERIC(12, 4) NOT NULL,
    unit_price NUMERIC(12, 4) NOT NULL,
    course VARCHAR(32) NOT NULL DEFAULT 'MAIN', -- 'STARTER', 'MAIN', 'DESSERT', 'BEVERAGE'
    modifiers JSONB,                           -- e.g. ["Medium Rare", "No Onions", "Extra Cheese"]
    kitchen_station VARCHAR(32) NOT NULL DEFAULT 'GRILL', -- 'GRILL', 'FRY', 'PIZZA', 'SALAD', 'BAR'
    kitchen_status VARCHAR(32) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'PREPARING', 'READY', 'SERVED'
    total_amount NUMERIC(12, 4) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Recipes / Bill of Materials (BOM) Auto-Ingredient Deduction
CREATE TABLE IF NOT EXISTS recipes_bom (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    menu_product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE, -- e.g. Wagyu Burger
    ingredient_product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE, -- e.g. Burger Bun, Patty, Sauce
    quantity_required NUMERIC(12, 4) NOT NULL, -- e.g. 1.0 bun, 0.150 kg beef patty
    unit_of_measure VARCHAR(16) NOT NULL,
    yield_percentage NUMERIC(5, 2) NOT NULL DEFAULT 100.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_recipe_component UNIQUE (menu_product_id, ingredient_product_id)
);

CREATE INDEX IF NOT EXISTS idx_recipes_menu ON recipes_bom(menu_product_id);

-- 4. Bar Open Bottles & Pour Variance Tracking
CREATE TABLE IF NOT EXISTS bar_bottles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    bottle_label_id VARCHAR(64) NOT NULL, -- Barcode/Tag on this physical open bottle
    total_volume_ml NUMERIC(8, 2) NOT NULL, -- e.g. 750ml
    remaining_volume_ml NUMERIC(8, 2) NOT NULL,
    total_sold_ml NUMERIC(8, 2) NOT NULL DEFAULT 0.0,
    status VARCHAR(32) NOT NULL DEFAULT 'OPEN', -- 'OPEN', 'DEPLETED', 'DISCARDED'
    opened_by UUID REFERENCES users(id) ON DELETE SET NULL,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    depleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS bar_pour_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bottle_id UUID NOT NULL REFERENCES bar_bottles(id) ON DELETE CASCADE,
    order_id UUID REFERENCES dining_orders(id) ON DELETE SET NULL,
    pour_volume_ml NUMERIC(8, 2) NOT NULL, -- e.g. 30ml
    bartender_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ------------------------------------------------------------------------------
-- Migration: 00080_customers_crm_and_credit.sql
-- ------------------------------------------------------------------------------
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


-- ------------------------------------------------------------------------------
-- Migration: 00090_finance_accounting_gl.sql
-- ------------------------------------------------------------------------------
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


-- ------------------------------------------------------------------------------
-- Migration: 00100_kenya_compliance_etims_mpesa.sql
-- ------------------------------------------------------------------------------
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


-- ------------------------------------------------------------------------------
-- Migration: 00110_hr_and_kenya_payroll.sql
-- ------------------------------------------------------------------------------
-- ==============================================================================
-- 00110_hr_and_kenya_payroll.sql
-- Human Resources, Attendance, Shifts & Kenyan Statutory Payroll (PAYE, NSSF, SHIF, Housing Levy)
-- ==============================================================================

-- 1. Employees Master
CREATE TABLE IF NOT EXISTS employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Optional link to login user
    employee_number VARCHAR(64) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    national_id VARCHAR(50) NOT NULL,
    kra_pin VARCHAR(50) NOT NULL, -- Required for statutory PAYE
    nssf_number VARCHAR(50),
    shif_number VARCHAR(50),      -- Social Health Insurance Fund
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(255),
    job_title VARCHAR(100) NOT NULL, -- 'CASHIER', 'STOREKEEPER', 'WAITER', 'CHEF', 'BARTENDER', 'MANAGER'
    basic_salary NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    housing_allowance NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    transport_allowance NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    bank_name VARCHAR(100),
    bank_account_number VARCHAR(100),
    employment_status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE', -- 'ACTIVE', 'ON_LEAVE', 'TERMINATED'
    hire_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_emp_num UNIQUE (organization_id, employee_number)
);

CREATE INDEX IF NOT EXISTS idx_employees_branch ON employees(branch_id, employment_status);

-- 2. Biometric / PIN Attendance Logs
CREATE TABLE IF NOT EXISTS attendance_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    clock_in TIMESTAMPTZ NOT NULL,
    clock_out TIMESTAMPTZ,
    total_hours NUMERIC(5, 2),
    overtime_hours NUMERIC(5, 2) DEFAULT 0.00,
    source VARCHAR(32) NOT NULL DEFAULT 'POS_TERMINAL', -- 'POS_TERMINAL', 'BIOMETRIC_DEVICE', 'MANUAL'
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_logs(employee_id, clock_in);

-- 3. Kenyan Statutory Payroll Runs & Payslips
CREATE TABLE IF NOT EXISTS payroll_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    payroll_month INT NOT NULL, -- 1-12
    payroll_year INT NOT NULL,  -- e.g. 2026
    total_gross_pay NUMERIC(14, 4) NOT NULL DEFAULT 0.0000,
    total_paye_tax NUMERIC(14, 4) NOT NULL DEFAULT 0.0000,
    total_nssf NUMERIC(14, 4) NOT NULL DEFAULT 0.0000,
    total_shif NUMERIC(14, 4) NOT NULL DEFAULT 0.0000,
    total_housing_levy NUMERIC(14, 4) NOT NULL DEFAULT 0.0000,
    total_net_pay NUMERIC(14, 4) NOT NULL DEFAULT 0.0000,
    status VARCHAR(32) NOT NULL DEFAULT 'DRAFT', -- 'DRAFT', 'APPROVED', 'PAID'
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payroll_period UNIQUE (organization_id, payroll_year, payroll_month)
);

CREATE TABLE IF NOT EXISTS payslips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payroll_run_id UUID NOT NULL REFERENCES payroll_runs(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    
    -- Earnings
    basic_salary NUMERIC(12, 4) NOT NULL,
    allowances NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    overtime_pay NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    gross_pay NUMERIC(12, 4) NOT NULL,
    
    -- Kenya Statutory Deductions
    paye_tax NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,       -- KRA Pay As You Earn
    nssf_tier1 NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,     -- NSSF Tier 1
    nssf_tier2 NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,     -- NSSF Tier 2
    shif_deduction NUMERIC(12, 4) NOT NULL DEFAULT 0.0000, -- SHIF (2.75% of gross)
    housing_levy NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,   -- Affordable Housing Levy (1.5%)
    salary_advance_deduction NUMERIC(12, 4) NOT NULL DEFAULT 0.0000,
    
    net_pay NUMERIC(12, 4) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ------------------------------------------------------------------------------
-- Migration: 00120_sync_events_and_cursors.sql
-- ------------------------------------------------------------------------------
-- ==============================================================================
-- 00120_sync_events_and_cursors.sql
-- Native Offline Delta Synchronization Engine: Events Journal & Device Watermark Cursors
-- Replaces external PowerSync service with zero-dependency native sync
-- ==============================================================================

-- 1. Sync Events Journal
CREATE TABLE IF NOT EXISTS sync_events (
    id BIGSERIAL PRIMARY KEY,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id) ON DELETE SET NULL,
    client_event_id UUID NOT NULL,
    event_type VARCHAR(64) NOT NULL,    -- 'INSERT', 'UPDATE', 'DELETE'
    entity_type VARCHAR(64) NOT NULL,   -- 'SALE', 'STOCK_MOVEMENT', 'CASHIER_SHIFT', 'PRICE_CHANGE'
    entity_id UUID NOT NULL,
    payload JSONB NOT NULL,
    client_timestamp TIMESTAMPTZ,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sync_event UNIQUE (organization_id, client_event_id)
);

CREATE INDEX IF NOT EXISTS idx_sync_events_pull 
ON sync_events (organization_id, branch_id, id ASC);

CREATE INDEX IF NOT EXISTS idx_sync_events_client 
ON sync_events (organization_id, client_event_id);

CREATE INDEX IF NOT EXISTS idx_sync_events_entity 
ON sync_events (organization_id, entity_type, entity_id);

-- 2. Device Watermark Cursors
CREATE TABLE IF NOT EXISTS device_cursors (
    device_id UUID PRIMARY KEY REFERENCES devices(id) ON DELETE CASCADE,
    last_event_id BIGINT NOT NULL DEFAULT 0,
    last_synced_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_device_cursors_synced 
ON device_cursors (last_synced_at DESC);

-- 3. Ensure Unique Index on (branch_id, product_id) for idempotent stock balance upserts
CREATE UNIQUE INDEX IF NOT EXISTS uq_stock_balances_branch_product 
ON stock_balances (branch_id, product_id);



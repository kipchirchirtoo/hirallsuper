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

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

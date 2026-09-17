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

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

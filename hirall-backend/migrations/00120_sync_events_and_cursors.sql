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

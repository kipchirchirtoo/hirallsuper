use axum::{
    extract::{Path, Query, State},
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::MaybeAuthUser;
use crate::core::errors::AppResult;

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Device {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub branch_id: Uuid,
    pub device_uuid: String,
    pub device_name: String,
    pub device_type: String,
    pub platform: String,
    pub last_seen_at: Option<DateTime<Utc>>,
    pub sync_status: String,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct DeviceQuery {
    pub branch_id: Option<Uuid>,
}

#[derive(Debug, Deserialize)]
pub struct RegisterDeviceRequest {
    pub branch_id: Uuid,
    pub device_uuid: String,
    pub device_name: String,
    pub device_type: Option<String>,
    pub platform: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct DeviceRegistrationResponse {
    pub device: Device,
    pub branch_name: String,
    pub organization_name: String,
    pub currency: String,
}

#[derive(Debug, sqlx::FromRow)]
struct DeviceMetaRow {
    pub branch_name: String,
    pub org_name: String,
    pub currency: String,
}

pub async fn register_or_pair_device(
    maybe_auth: MaybeAuthUser,
    State(state): State<AppState>,
    Json(payload): Json<RegisterDeviceRequest>,
) -> AppResult<Json<DeviceRegistrationResponse>> {
    let pool = state.pool().await;
    let org_id = if let Some(auth) = maybe_auth.0 {
        auth.organization_id
    } else {
        sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&pool)
        .await?
        .unwrap_or_else(|| Uuid::parse_str("67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad").unwrap())
    };

    let device_type = payload.device_type.unwrap_or_else(|| "POS_DESKTOP".to_string());
    let platform = payload.platform.unwrap_or_else(|| "WINDOWS".to_string());

    let device = sqlx::query_as::<_, Device>(
        r#"
        INSERT INTO devices (
            organization_id, branch_id, device_uuid, device_name, device_type, platform,
            last_seen_at, sync_status, is_active
        )
        VALUES ($1, $2, $3, $4, $5, $6, NOW(), 'ONLINE', true)
        ON CONFLICT (organization_id, device_uuid)
        DO UPDATE SET
            branch_id = EXCLUDED.branch_id,
            device_name = EXCLUDED.device_name,
            platform = EXCLUDED.platform,
            last_seen_at = NOW(),
            sync_status = 'ONLINE',
            updated_at = NOW()
        RETURNING
            id, organization_id, branch_id, device_uuid, device_name, device_type, platform,
            last_seen_at, sync_status, is_active, created_at, updated_at
        "#,
    )
    .bind(org_id)
    .bind(payload.branch_id)
    .bind(payload.device_uuid)
    .bind(payload.device_name)
    .bind(device_type)
    .bind(platform)
    .fetch_one(&pool)
    .await?;

    // Also ensure a cursor entry exists for this device
    sqlx::query(
        r#"
        INSERT INTO device_cursors (device_id, last_event_id, last_synced_at)
        VALUES ($1, 0, NOW())
        ON CONFLICT (device_id) DO NOTHING
        "#,
    )
    .bind(device.id)
    .execute(&pool)
    .await?;

    let meta = sqlx::query_as::<_, DeviceMetaRow>(
        r#"
        SELECT b.name as branch_name, o.name as org_name, o.currency
        FROM branches b
        JOIN organizations o ON o.id = b.organization_id
        WHERE b.id = $1
        "#,
    )
    .bind(device.branch_id)
    .fetch_one(&pool)
    .await?;

    Ok(Json(DeviceRegistrationResponse {
        device,
        branch_name: meta.branch_name,
        organization_name: meta.org_name,
        currency: meta.currency,
    }))
}

pub async fn list_devices(
    maybe_auth: MaybeAuthUser,
    Query(params): Query<DeviceQuery>,
    State(state): State<AppState>,
) -> AppResult<Json<Vec<Device>>> {
    let pool = state.pool().await;
    let org_id = if let Some(auth) = maybe_auth.0 {
        auth.organization_id
    } else {
        sqlx::query_scalar::<_, Uuid>(
            "SELECT id FROM organizations WHERE status = 'ACTIVE' ORDER BY created_at ASC LIMIT 1",
        )
        .fetch_optional(&pool)
        .await?
        .unwrap_or_else(|| Uuid::parse_str("67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad").unwrap())
    };

    let devices = if let Some(bid) = params.branch_id {
        sqlx::query_as::<_, Device>(
            r#"
            SELECT id, organization_id, branch_id, device_uuid, device_name, device_type, platform,
                   last_seen_at, sync_status, is_active, created_at, updated_at
            FROM devices
            WHERE organization_id = $1 AND branch_id = $2
            ORDER BY created_at DESC
            "#,
        )
        .bind(org_id)
        .bind(bid)
        .fetch_all(&pool)
        .await?
    } else {
        sqlx::query_as::<_, Device>(
            r#"
            SELECT id, organization_id, branch_id, device_uuid, device_name, device_type, platform,
                   last_seen_at, sync_status, is_active, created_at, updated_at
            FROM devices
            WHERE organization_id = $1
            ORDER BY created_at DESC
            "#,
        )
        .bind(org_id)
        .fetch_all(&pool)
        .await?
    };

    Ok(Json(devices))
}

pub async fn device_heartbeat(
    Path(device_uuid): Path<String>,
    State(state): State<AppState>,
) -> AppResult<Json<serde_json::Value>> {
    sqlx::query(
        r#"
        UPDATE devices
        SET last_seen_at = NOW(), sync_status = 'ONLINE', updated_at = NOW()
        WHERE device_uuid = $1
        "#,
    )
    .bind(device_uuid)
    .execute(&state.pool().await)
    .await?;

    Ok(Json(serde_json::json!({
        "status": "ok",
        "server_time": Utc::now()
    })))
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", get(list_devices))
        .route("/register", post(register_or_pair_device))
        .route("/heartbeat/:device_uuid", post(device_heartbeat))
}

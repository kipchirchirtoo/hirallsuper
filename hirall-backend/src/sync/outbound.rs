use axum::{
    extract::{Query, State},
    Json,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

use crate::app::state::AppState;
use crate::core::auth::AuthUser;
use crate::core::errors::AppResult;

#[derive(Debug, Deserialize)]
pub struct PullSyncQuery {
    pub device_uuid: String,
    pub branch_id: Uuid,
    pub last_event_id: Option<i64>,
    pub limit: Option<i64>,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct OutboundSyncItem {
    pub id: i64,
    pub organization_id: Uuid,
    pub branch_id: Uuid,
    pub device_id: Option<Uuid>,
    pub event_type: String,
    pub entity_type: String,
    pub entity_id: Uuid,
    pub payload: Value,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct PullSyncResponse {
    pub events: Vec<OutboundSyncItem>,
    pub new_cursor: i64,
    pub has_more: bool,
    pub server_time: DateTime<Utc>,
}

pub async fn pull_sync_deltas(
    auth: AuthUser,
    Query(params): Query<PullSyncQuery>,
    State(state): State<AppState>,
) -> AppResult<Json<PullSyncResponse>> {
    let cursor = params.last_event_id.unwrap_or(0);
    let limit = params.limit.unwrap_or(100).min(500);

    let events = sqlx::query_as::<_, OutboundSyncItem>(
        r#"
        SELECT id, organization_id, branch_id, device_id, event_type, entity_type,
               entity_id, payload, created_at
        FROM sync_events
        WHERE organization_id = $1
          AND branch_id = $2
          AND id > $3
        ORDER BY id ASC
        LIMIT $4
        "#,
    )
    .bind(auth.organization_id)
    .bind(params.branch_id)
    .bind(cursor)
    .bind(limit)
    .fetch_all(&state.pool().await)
    .await?;

    let new_cursor = events.last().map(|e| e.id).unwrap_or(cursor);
    let has_more = events.len() as i64 == limit;

    // Update device cursor watermark
    let _ = sqlx::query(
        r#"
        UPDATE device_cursors dc
        SET last_event_id = GREATEST(dc.last_event_id, $1),
            last_synced_at = NOW()
        FROM devices d
        WHERE dc.device_id = d.id AND d.device_uuid = $2
        "#,
    )
    .bind(new_cursor)
    .bind(&params.device_uuid)
    .execute(&state.pool().await)
    .await;

    Ok(Json(PullSyncResponse {
        events,
        new_cursor,
        has_more,
        server_time: Utc::now(),
    }))
}
